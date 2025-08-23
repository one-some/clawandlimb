#include "voxelmesh.h"
#include "march_data.h"
#include "noisemanager.h"
#include <godot_cpp/variant/vector3i.hpp>

#include <godot_cpp/classes/surface_tool.hpp>
#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/templates/hash_set.hpp>
#include <godot_cpp/templates/vector.hpp>

// Kill it
#include <unordered_map>

using namespace godot;

static const Vector3i FACE_DIRS[6] = {
    {1, 0, 0},
    {-1, 0, 0},
    {0, 1, 0},
    {0, -1, 0},
    {0, 0, 1},
    {0, 0, -1}};

bool in_padded(const Vector3 &pos)
{
    if (pos.x < 0)
        return false;
    if (pos.y < 0)
        return false;
    if (pos.z < 0)
        return false;
    if (pos.x >= PADDED_SIZE)
        return false;
    if (pos.y >= PADDED_SIZE)
        return false;
    if (pos.z >= PADDED_SIZE)
        return false;
    return true;
}

void VoxelMesh::delete_area(const AABB &area)
{
    for (int x = area.position.x; x < area.position.x + area.size.x; x++)
    {
        for (int y = area.position.y; y < area.position.y + area.size.y; y++)
        {
            for (int z = area.position.z; z < area.position.z + area.size.z; z++)
            {
                Vector3i pos = Vector3i(x, y, z);
                if (destroyed_voxels.has(pos))
                    continue;

                // density[get_index(x, y, z)] = -999.0f;
                destroyed_voxels.insert(pos);
            }
        }
    }
    generate_mesh();
}

VoxelMesh::Biome VoxelMesh::get_biome(const Vector2 &pos) {
    // TODO: Get legit noises for here..
    const float POS_MULT = 0.005;

    float humidity = noise.get_noise(noise.low_noise, pos * POS_MULT);
    humidity = Math::clamp((humidity + 1.0f) / 2.0f, 0.0f, 1.0f);

    float temperature = noise.get_noise(noise.low_noise, (pos * POS_MULT) + Vector2(120000.0, 100000.0));
    temperature = Math::clamp((temperature + 1.0f) / 2.0f, 0.0f, 1.0f);

    // If this gets expanded there better be a cleaner way to do this...
    if (humidity > 0.5f) {
        if (temperature > 0.5f) {
            // TODO: JUNGLE?
            return Biome::GRASS;
        } else {
            return Biome::GRASS;
        }
    } else {
        if (temperature > 0.5) {
            return Biome::DESERT;
        } else {
            return Biome::TUNDRA;
        }
    }
}

uint16_t VoxelMesh::get_material(const Vector3 &pos, float density, VoxelMesh::Biome biome) {
    if (density > 3.0f) return Materials::STONE;

    switch (biome) {
        case Biome::GRASS:
            if (pos.y < sea_level + 1.0f) return Materials::SAND;
            if (density > 1.5f) return Materials::DIRT;

            return Materials::GRASS;

        case Biome::TUNDRA:
            if (pos.y < sea_level + 1.0f) return Materials::DIRT;
            if (density > 1.5f) return Materials::DIRT;

            return Materials::SNOW;

        case Biome::DESERT:
            return Materials::SAND;
    }

    // SHOULDN'T HAPPEN!!!
    return Materials::PLANK;
}

void VoxelMesh::generate_chunk_data()
{
    const Vector3 global_base = chunk_pos * (real_t)CHUNK_SIZE;
    HashSet<Vector3> resource_cells;
    resource_position_candidates.clear();

    for (int x = 0; x < PADDED_SIZE; x++)
    {
        for (int y = PADDED_SIZE - 1; y >= 0; y--)
        {
            for (int z = 0; z < PADDED_SIZE; z++)
            {
                Vector3 local_pos = Vector3(x, y, z);
                Vector3 global_pos = global_base + local_pos;
                Vector2 global_2d_pos = Vector2(global_pos.x, global_pos.z);

                float density = noise.get_noise_3d(global_pos);
                Biome biome = get_biome(global_2d_pos); 

                size_t idx = get_index(local_pos);
                voxel_densities[idx] = density;

                uint16_t material = get_material(global_pos, density, biome);
                voxel_materials[idx] = material;

                Vector3 voxel_above = local_pos + Vector3(0, 1, 0);
                if (
                    material == Materials::GRASS && density > 0.0f && in_padded(voxel_above) && UtilityFunctions::randf() < 0.02)
                {
                    size_t above_idx = get_index(voxel_above);
                    float above_density = voxel_densities[above_idx];

                    if (above_density <= 0.0)
                    {
                        float d0 = density;
                        float d1 = above_density;
                        float t = 0.0f;
                        float bottom = d0 - d1;

                        if (!Math::is_equal_approx(bottom, 0.0f))
                        {
                            t = Math::clamp(d0 / bottom, 0.0f, 1.0f);
                        }

                        auto pos = local_pos + Vector3(0.0, t, 0.0);
                        auto cell = ((chunk_pos * CHUNK_SIZE) + pos).round();
                        if (!resource_cells.has(cell))
                        {
                            resource_cells.insert(cell);
                            resource_position_candidates.push_back(pos);
                        }
                    }
                }

                // TODO: TREES
            }
        }
    }
}

void VoxelMesh::generate_mesh()
{
    using ST = SurfaceTool;
    Ref<SurfaceTool> st;
    st.instantiate();
    st->begin(Mesh::PRIMITIVE_TRIANGLES);

    st->set_custom_format(0, SurfaceTool::CUSTOM_RGBA_FLOAT);

    for (int x = 0; x < CHUNK_SIZE; x++)
    {
        for (int y = 0; y < CHUNK_SIZE; y++)
        {
            for (int z = 0; z < CHUNK_SIZE; z++)
            {

                int cx[8] = {x, x + 1, x + 1, x, x, x + 1, x + 1, x};
                int cy[8] = {y, y, y, y, y + 1, y + 1, y + 1, y + 1};
                int cz[8] = {z, z, z + 1, z + 1, z, z, z + 1, z + 1};

                float corner_densities[8];
                float corner_materials[8];

                unsigned char edge_table_index = 0x00;

                for (int i = 0; i < 8; i++)
                {
                    size_t idx = get_index(cx[i], cy[i], cz[i]);
                    corner_densities[i] = voxel_densities[idx];
                    corner_materials[i] = voxel_materials[idx];

                    if (corner_densities[i] > 0.0)
                        edge_table_index |= 1 << i;
                }

                if (edge_table_index == 0x00 || edge_table_index == 0xFF)
                {
                    // All surface / air. No need to draw
                    continue;
                }

                uint16_t edge_mask = EDGES[edge_table_index];
                Vector3 edge_verts[12] = {};

                for (int e = 0; e < 12; e++)
                {
                    if (!(edge_mask & (1 << e)))
                        continue;

                    const int idx_0 = EDGE_TO_CORNERS[e][0];
                    const int idx_1 = EDGE_TO_CORNERS[e][1];

                    Vector3 p0 = Vector3(
                        (real_t)cx[idx_0],
                        (real_t)cy[idx_0],
                        (real_t)cz[idx_0]);

                    Vector3 p1 = Vector3(
                        (real_t)cx[idx_1],
                        (real_t)cy[idx_1],
                        (real_t)cz[idx_1]);

                    float d0 = corner_densities[idx_0];
                    float d1 = corner_densities[idx_1];

                    float t = 0.5f;
                    float bottom = d1 - d0;
                    if (!Math::is_equal_approx(bottom, 0.0f))
                    {
                        t = Math::clamp(-d0 / bottom, 0.0f, 1.0f);
                    }

                    edge_verts[e] = p0.lerp(p1, t);
                }

                const int *tri = TRI_TABLE[edge_table_index];

                Vector3i voxel = Vector3i(x, y, z);
                if (destroyed_voxels.has(voxel))
                {
                    // This has been destroyed. Render with rigid borders.

                    for (int f = 0; f < 6; f++)
                    {
                        Vector3i neighbor_pos = voxel + FACE_DIRS[f];

                        if (destroyed_voxels.has(neighbor_pos))
                        {
                            continue;
                        }

                        Vector3 face_corners_pos[4];
                        float face_corners_den[4];
                        unsigned char square_edge_index = 0;

                        for (int i = 0; i < 4; i++)
                        {
                            int corner_idx = FACE_CORNERS[f][i];
                            face_corners_pos[i] = Vector3(
                                cx[corner_idx],
                                cy[corner_idx],
                                cz[corner_idx]);
                            face_corners_den[i] = corner_densities[corner_idx];
                            if (face_corners_den[i] > 0.0)
                                square_edge_index |= (1 << i);
                        }

                        if (square_edge_index == 0 || square_edge_index == 15)
                            continue;

                        Vector3 rim_verts[4];
                        for (int i = 0; i < 4; i++)
                        {
                            const int c0_idx = i;
                            const int c1_idx = (i + 1) % 4;

                            const Vector3 &p0 = face_corners_pos[c0_idx];
                            const Vector3 &p1 = face_corners_pos[c1_idx];
                            const float d0 = face_corners_den[c0_idx];
                            const float d1 = face_corners_den[c1_idx];

                            float t = 0.5f;
                            float bottom_den = d1 - d0;
                            if (!Math::is_equal_approx(bottom_den, 0.0f))
                            {
                                t = Math::clamp(-d0 / bottom_den, 0.0f, 1.0f);
                            }
                            rim_verts[i] = p0.lerp(p1, t);
                        }

                        const int *edges = SQUARES_EDGES[square_edge_index];
                        for (int i = 0; edges[i] != -1; i += 2)
                        {
                            Vector3 v0_top = rim_verts[edges[i]];
                            Vector3 v1_top = rim_verts[edges[i + 1]];

                            Vector3 v0_bot = v0_top - Vector3(0, 1, 0);
                            Vector3 v1_bot = v1_top - Vector3(0, 1, 0);

                            st->add_vertex(v0_top);
                            st->add_vertex(v1_bot);
                            st->add_vertex(v1_top);

                            st->add_vertex(v0_top);
                            st->add_vertex(v0_bot);
                            st->add_vertex(v1_bot);
                        }
                    }

                    continue;
                }

                for (int ti = 0; tri[ti] != -1; ti += 3)
                {
                    Vector3 v0 = edge_verts[tri[ti + 0]];
                    Vector3 v1 = edge_verts[tri[ti + 2]];
                    Vector3 v2 = edge_verts[tri[ti + 1]];

                    Vector3 P[3] = {v0, v1, v2};

                    for (int v = 0; v < 3; v++)
                    {
                        Vector3 p = P[v];
                        Vector3 rel = p - Vector3(x, y, z);

                        float rx = rel.x;
                        float ry = rel.y;
                        float rz = rel.z;

                        float corner_weights[8] = {
                            (1 - rx) * (1 - ry) * (1 - rz),
                            (rx) * (1 - ry) * (1 - rz),
                            (rx) * (1 - ry) * (rz),
                            (1 - rx) * (1 - ry) * (rz),
                            (1 - rx) * (ry) * (1 - rz),
                            (rx) * (ry) * (1 - rz),
                            (rx) * (ry) * (rz),
                            (1 - rx) * (ry) * (rz)};

                        std::unordered_map<int, float> accum;
                        for (int c = 0; c < 8; c++)
                        {
                            accum[corner_materials[c]] += corner_weights[c];
                        }

                        struct MatW
                        {
                            int id;
                            float w;
                        };

                        MatW top[4] = {
                            {-1, 0},
                            {-1, 0},
                            {-1, 0},
                            {-1, 0},
                        };

                        for (const auto &kv : accum)
                        {
                            int id = kv.first;
                            float w = kv.second;

                            for (int k = 0; k < 4; k++)
                            {
                                if (w <= top[k].w)
                                    continue;
                                for (int j = 3; j > k; j--)
                                {
                                    top[j] = top[j - 1];
                                }
                                top[k] = {id, w};
                                break;
                            }
                        }

                        float weight_sum = top[0].w + top[1].w + top[2].w + top[3].w;
                        if (weight_sum > 0.0)
                        {
                            top[0].w /= weight_sum;
                            top[1].w /= weight_sum;
                            top[2].w /= weight_sum;
                            top[3].w /= weight_sum;
                        }

                        st->set_color(Color(top[0].w, top[1].w, top[2].w, top[3].w));
                        st->set_custom(0, Color(top[0].id, top[1].id, top[2].id, top[3].id));

                        st->add_vertex(p);
                    }
                }
            }
        }
    }

    st->generate_normals();
    st->index();
    Ref<ArrayMesh> mesh = st->commit();
    set_mesh(mesh);

    emit_signal("finished_mesh_generation");
}

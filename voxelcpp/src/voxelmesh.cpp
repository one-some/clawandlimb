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

void VoxelMesh::delete_area(const AABB &area, bool soft_delete)
{
    for (int x = area.position.x; x < area.position.x + area.size.x; x++)
    {
        for (int y = area.position.y; y < area.position.y + area.size.y; y++)
        {
            for (int z = area.position.z; z < area.position.z + area.size.z; z++)
            {
                if (soft_delete)
                {
                    voxel_densities[get_index(x, y, z)] = -999.0f;
                    continue;
                }

                Vector3i pos = Vector3i(x, y, z);
                if (destroyed_voxels.has(pos))
                    continue;
                destroyed_voxels.insert(pos);
                // voxel_densities[get_index(x, y, z)] = 0.0f;
            }
        }
    }
    generate_mesh();
}

VoxelMesh::Biome VoxelMesh::get_biome(const Vector2 &pos)
{
    // TODO: Get legit noises for here..
    const float POS_MULT = 0.005;

    float humidity = noise->get_noise(noise->low_noise, pos * POS_MULT);
    humidity = Math::clamp((humidity + 1.0f) / 2.0f, 0.0f, 1.0f);
    humidity = Math::smoothstep(0.0f, 1.0f, humidity);

    float temperature = noise->get_noise(noise->low_noise, (pos * POS_MULT) + Vector2(120000.0, 100000.0));
    temperature = Math::clamp((temperature + 1.0f) / 2.0f, 0.0f, 1.0f);
    temperature = Math::smoothstep(0.0f, 1.0f, temperature);

    // If this gets expanded there better be a cleaner way to do this...
    if (humidity > 0.5f)
    {
        if (temperature > 0.5f)
        {
            // TODO: JUNGLE?
            return BIOME_GRASS;
        }
        else
        {
            return BIOME_GRASS;
        }
    }
    else
    {
        if (temperature > 0.5)
        {
            return BIOME_DESERT;
        }
        else
        {
            return BIOME_TUNDRA;
        }
    }
}

uint16_t VoxelMesh::get_material(const Vector3 &pos, float density, VoxelMesh::Biome biome)
{
    if (density > 3.0f)
        return MATERIAL_STONE;

    switch (biome)
    {
    case BIOME_GRASS:
        if (pos.y < sea_level + 1.0f)
            return MATERIAL_SAND;
        if (density > 1.5f)
            return MATERIAL_DIRT;

        return MATERIAL_GRASS;

    case BIOME_TUNDRA:
        if (pos.y < sea_level + 1.0f)
            return MATERIAL_DIRT;
        if (density > 1.5f)
            return MATERIAL_DIRT;

        return MATERIAL_SNOW;

    case BIOME_DESERT:
        return MATERIAL_SAND;
    }

    // SHOULDN'T HAPPEN!!!
    return MATERIAL_PLANK;
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

                float density = noise->get_terrain_noise(global_pos);
                Biome biome = get_biome(global_2d_pos);

                size_t idx = get_index(local_pos);
                voxel_densities[idx] = density;

                uint16_t material = get_material(global_pos, density, biome);
                voxel_materials[idx] = material;

                Vector3 voxel_above = local_pos + Vector3(0, 1, 0);
                if (
                    density > 0.0f && in_padded(voxel_above) && UtilityFunctions::randf() < 0.02)
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

Vector2 get_triplanar_uv(const Vector3 &pos, const Vector3& normal) {
    Vector3 abs_normal = normal.abs();

    if (abs_normal.x > abs_normal.y && abs_normal.x > abs_normal.z) {
        // X-axis projection (side)
        return Vector2(pos.z, pos.y);
    } else if (abs_normal.y > abs_normal.x && abs_normal.y > abs_normal.z) {
        // Y-axis projection (top/bottom)
        return Vector2(pos.x, pos.z);
    } else {
        // Z-axis projection (front/back)
        return Vector2(pos.x, pos.y);
    }
}

void VoxelMesh::generate_mesh()
{
    // using ST = SurfaceTool;
    // Ref<SurfaceTool> st;
    // st.instantiate();
    // st->begin(Mesh::PRIMITIVE_TRIANGLES);

    // st->set_custom_format(0, SurfaceTool::CUSTOM_RGBA_FLOAT);

    PackedVector3Array vertices;
    PackedVector3Array normals;
    PackedColorArray colors_for_weights;
    PackedByteArray custom_for_mat_ids;

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
                    Vector3 base_corners[8];
                    for (int i = 0; i < 8; ++i)
                    {
                        base_corners[i] = Vector3(cx[i], cy[i], cz[i]);
                    }

                    Vector3 final_corners[8];
                    for (int i = 0; i < 8; ++i)
                    {
                        if (i < 4)
                        {
                            final_corners[i] = base_corners[i];
                        }
                        else
                        {
                            int bottom_corner_idx = i - 4;
                            float d_bot = corner_densities[bottom_corner_idx];
                            float d_top = corner_densities[i];

                            if ((d_bot > 0.0f) == (d_top > 0.0f))
                            {
                                final_corners[i] = (d_top > 0.0f) ? base_corners[i] : base_corners[bottom_corner_idx];
                            }
                            else
                            {
                                float t = 0.0f;
                                float bottom_den = d_top - d_bot;
                                if (!Math::is_equal_approx(bottom_den, 0.0f))
                                {
                                    t = Math::clamp(-d_bot / bottom_den, 0.0f, 1.0f);
                                }
                                final_corners[i] = base_corners[bottom_corner_idx].lerp(base_corners[i], t);
                            }
                        }
                    }

                    const int CUBE_FACES_CW[6][4] = {
                        {1, 5, 6, 2}, // +X face
                        {3, 7, 4, 0}, // -X face
                        {7, 6, 5, 4}, // +Y face (Top)
                        {0, 1, 2, 3}, // -Y face (Bottom)
                        {2, 6, 7, 3}, // +Z face
                        {1, 0, 4, 5}  // -Z face
                    };

                    for (int f = 0; f < 6; f++)
                    {
                        Vector3i neighbor_pos = voxel + FACE_DIRS[f];
                        if (destroyed_voxels.has(neighbor_pos))
                        {
                            continue;
                        }

                        if (f == 2)
                        {
                            continue;
                        }

                        const int *face_corner_indices = CUBE_FACES_CW[f];

                        int vertex_indices[6] = {
                            face_corner_indices[0], face_corner_indices[1], face_corner_indices[2],
                            face_corner_indices[0], face_corner_indices[2], face_corner_indices[3]};

                        for (int i = 0; i < 6; i++)
                        {
                            int corner_idx = vertex_indices[i];
                            Vector3 vertex_pos = final_corners[corner_idx];

                            int mat_id;
                            if (corner_idx < 4)
                            {
                                mat_id = corner_materials[corner_idx];
                            }
                            else
                            {
                                float d_top = corner_densities[corner_idx];
                                mat_id = (d_top > 0.0f) ? corner_materials[corner_idx] : corner_materials[corner_idx - 4];
                            }

                            vertices.append(vertex_pos);

                            colors_for_weights.append(Color(1.0f, 0.0f, 0.0f, 0.0f));
                            custom_for_mat_ids.append(mat_id);
                            custom_for_mat_ids.append(0);
                            custom_for_mat_ids.append(0);
                            custom_for_mat_ids.append(0);
                        }
                    }

                    continue;
                }

                for (int ti = 0; tri[ti] != -1; ti += 3)
                {
                    // NOTE: THIS FREAKING WINDING ORDER is normal for Godot!!!
                    Vector3 v0 = edge_verts[tri[ti + 0]];
                    Vector3 v1 = edge_verts[tri[ti + 2]];
                    Vector3 v2 = edge_verts[tri[ti + 1]];

                    Vector3 norm = (v2 - v0).cross(v1 - v0).normalized();
                    normals.append(norm);
                    normals.append(norm);
                    normals.append(norm);

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

                        vertices.append(p);
                        colors_for_weights.append(Color(top[0].w, top[1].w, top[2].w, top[3].w));

                        custom_for_mat_ids.append(top[0].id);
                        custom_for_mat_ids.append(top[1].id);
                        custom_for_mat_ids.append(top[2].id);
                        custom_for_mat_ids.append(top[3].id);
                    }
                }
            }
        }
    }

    Array surface_array;
    surface_array.resize(Mesh::ARRAY_MAX);

    if (vertices.size() == 0) return;

    surface_array[Mesh::ARRAY_VERTEX] = vertices;
    surface_array[Mesh::ARRAY_NORMAL] = normals;
    surface_array[Mesh::ARRAY_COLOR] = colors_for_weights;
    surface_array[Mesh::ARRAY_CUSTOM0] = custom_for_mat_ids;

    Ref<ArrayMesh> mesh = memnew(ArrayMesh);
    mesh->add_surface_from_arrays(
        Mesh::PRIMITIVE_TRIANGLES,
        surface_array,
        Array(),
        Dictionary(),
        Mesh::ARRAY_CUSTOM0 << Mesh::ARRAY_CUSTOM_RGBA8_UNORM
    );

    call_deferred("set_mesh", mesh);
    call_deferred("emit_signal", "finished_mesh_generation", first_time_generated);
    first_time_generated = false;
}

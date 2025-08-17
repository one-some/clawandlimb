#include "voxelmesh.h"
#include "march_data.h"

#include <godot_cpp/classes/surface_tool.hpp>
#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/core/math.hpp>
#include <unordered_map>
#include <vector>

using namespace godot;

void VoxelMesh::generate_chunk_data() {
    if (!sample_noise.is_valid()) {
        UtilityFunctions::printerr("Callback invalid :-(");
        return;
    }

    const Vector3 global_base = chunk_pos * (real_t)CHUNK_SIZE;

    for (int x = 0; x < PADDED_SIZE; x++) {
        for (int y = 0; y < PADDED_SIZE; y++) {
            for (int z = 0; z < PADDED_SIZE; z++) {
                auto local_pos = Vector3(x, y, z);
                auto global_pos = global_base + local_pos;


                UtilityFunctions::print("Before call ", global_pos);
                // THE CRASH OCCURS AT THIS LINE AFTER SEVERAL LOOPS. We never see the "After call" message.
                Variant ret = sample_noise.callv(Array::make(global_pos));
                UtilityFunctions::print("After call");

                if (ret.get_type() != Variant::FLOAT) {
                    UtilityFunctions::printerr("Bad ret type for noise : ", Variant::get_type_name(ret.get_type()));
                    return;
                }

                // TODO: Assert type
                float den = ret;

                size_t idx = get_index(local_pos);
                density[idx] = den;
                // TODO: Mat through callback
                material[idx] = 1;

                UtilityFunctions::print("Looping...");
                // TODO: TREES
            }
        }

    }

    // We NEVER reach the end of generate_chunk_data, for even one chunk. I can confirm the crash is indeed in this function.
}

void VoxelMesh::generate_mesh() {
    using ST = SurfaceTool;
    Ref<SurfaceTool> st;
    st.instantiate();
    st->begin(Mesh::PRIMITIVE_TRIANGLES);

    st->set_custom_format(0, SurfaceTool::CUSTOM_RGBA_FLOAT);
    UtilityFunctions::print("Start");

    
    for (int x = 0; x < CHUNK_SIZE; x++) {
        for (int y = 0; y < CHUNK_SIZE; y++) {
            for (int z = 0; z < CHUNK_SIZE; z++) {
                UtilityFunctions::print("Loop");

                int cx[8] = { x, x+1, x+1, x, x, x+1, x+1, x };
                int cy[8] = { y, y, y, y, y+1, y+1, y+1, y+1 };
                int cz[8] = { z, z, z+1, z+1, z, z, z+1, z+1 };

                float corner_densities[8];
                float corner_materials[8];

                char edge_table_index = 0x00;

                for (int i = 0; i < 8; i++) {
                    size_t idx = get_index(cx[i], cy[i], cz[i]);
                    corner_densities[i] = density[idx];
                    corner_materials[i] = material[idx];

                    if (corner_densities[i] > 0.0) edge_table_index |= 1 << i;
                }

                if (edge_table_index == 0x00 || edge_table_index == 0xFF) {
                    // All surface / air. No need to draw
                    UtilityFunctions::print("All surface / air lol");
                    continue;
                }
                UtilityFunctions::print("Shits real");

                uint16_t edge_mask = EDGES[edge_table_index];
                Vector3 edge_verts[12] = {};

                for (int e = 0; e < 12; e++) {
                    if (!(edge_mask & (1 << e))) continue;

                    const int idx_0 = EDGE_TO_CORNERS[e][0];
                    const int idx_1 = EDGE_TO_CORNERS[e][1];

                    Vector3 p0 = Vector3(
                        (real_t) cx[idx_0],
                        (real_t) cy[idx_0],
                        (real_t) cz[idx_0]
                    );

                    Vector3 p1 = Vector3(
                        (real_t) cx[idx_1],
                        (real_t) cy[idx_1],
                        (real_t) cz[idx_1]
                    );

                    float d0 = corner_densities[idx_0];
                    float d1 = corner_densities[idx_1];

                    float t = 0.5f;
                    float bottom = d1 - d0;
                    if (!Math::is_equal_approx(bottom, 0.0f)) {
                        t = Math::clamp(-d0 / bottom, 0.0f, 1.0f);
                    }

                    edge_verts[e] = p0.lerp(p1, t);
                }

                const int *tri = TRI_TABLE[edge_table_index];
                for (int ti = 0; tri[ti] != -1; ti += 3) {
                    int e0 = tri[ti+0];
                    int e1 = tri[ti+1];
                    int e2 = tri[ti+2];

                    Vector3 P[3] = { edge_verts[e0], edge_verts[e1], edge_verts[e2] };

                    for (int v = 0; v < 3; v++) {
                        Vector3 p = P[v];
                        Vector3 rel = p - Vector3(x, y, z);

                        float rx = rel.x;
                        float ry = rel.y;
                        float rz = rel.z;

                        float corner_weights[8] = {
                            (1-rx) * (1-ry) * (1-rz),
                            (rx) * (1-ry) * (1-rz),
                            (rx) * (1-ry) * (rz),
                            (1-rx) * (1-ry) * (rz),
                            (1-rx) * (ry) * (1-rz),
                            (rx) * (ry) * (1-rz),
                            (rx) * (ry) * (rz),
                            (1-rx) * (ry) * (rz)
                        };

                        std::unordered_map<int, float> accum;
                        for (int c = 0; c < 8; c++) {
                            accum[corner_materials[c]] += corner_weights[c];
                        }

                        struct MatW {
                            int id;
                            float w;
                        };

                        MatW top[4] = {
                            { -1, 0},
                            { -1, 0},
                            { -1, 0},
                            { -1, 0},
                        };

                        for (const auto& kv : accum) {
                            int id = kv.first;
                            float w = kv.second;

                            for (int k = 0; k < 4; k++) {
                                if (w <= top[k].w) continue;
                                for (int j = 3; j > k; j--) {
                                    top[j] = top[j - 1];
                                }
                                top[k] = { id, w };
                                break;
                            }
                        }

                        float weight_sum = top[0].w + top[1].w + top[2].w + top[3].w;
                        if (weight_sum > 0.0) {
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
}

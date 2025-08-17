#ifndef VOXELMESH_H
#define VOXELMESH_H

#include "noisemanager.h"
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/typed_array.hpp>

namespace godot {

constexpr size_t CHUNK_SIZE = 16;
constexpr size_t PADDED_SIZE = CHUNK_SIZE + 1;

class VoxelMesh : public MeshInstance3D {
	GDCLASS(VoxelMesh, MeshInstance3D)

private:
    NoiseManager noise;
    Vector3 chunk_pos;
    PackedVector3Array resource_position_candidates;

    uint16_t material[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0 };
    float density[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0.0 };

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("generate_chunk_data"), &VoxelMesh::generate_chunk_data);
        ClassDB::bind_method(D_METHOD("generate_mesh"), &VoxelMesh::generate_mesh);
        ClassDB::bind_method(D_METHOD("set_pos", "pos"), &VoxelMesh::set_pos);
        ClassDB::bind_method(D_METHOD("get_resource_position_candidates"), &VoxelMesh::get_resource_position_candidates);

        ADD_SIGNAL(MethodInfo("finished_mesh_generation"));
    }

public:
    VoxelMesh() { }
    ~VoxelMesh() = default;

    PackedVector3Array get_resource_position_candidates() {
        return resource_position_candidates;
    }

    void set_pos(const Vector3 &pos) {
        chunk_pos = pos;
        set_global_position(pos * CHUNK_SIZE);
    }

    inline size_t get_index(int x, int y, int z) {
        // TODO: Dedup
        return (
            (size_t)x
            + ((size_t)y * PADDED_SIZE)
            + ((size_t)z * PADDED_SIZE * PADDED_SIZE)
        );
    }

    inline size_t get_index(Vector3& pos) {
        return (
            (size_t)pos.x
            + ((size_t)pos.y * PADDED_SIZE)
            + ((size_t)pos.z * PADDED_SIZE * PADDED_SIZE)
        );
    }

    void generate_chunk_data();
    void generate_mesh();
};

}

#endif

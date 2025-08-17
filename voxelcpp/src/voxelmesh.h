#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include "noisemanager.h"
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>

namespace godot {

constexpr size_t CHUNK_SIZE = 16;
constexpr size_t PADDED_SIZE = CHUNK_SIZE + 1;

class VoxelMesh : public MeshInstance3D {
	GDCLASS(VoxelMesh, MeshInstance3D)

private:
    NoiseManager noise;
    Vector3 chunk_pos;

    uint16_t material[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0 };
    float density[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0.0 };

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("generate_chunk_data"), &VoxelMesh::generate_chunk_data);
        ClassDB::bind_method(D_METHOD("generate_mesh"), &VoxelMesh::generate_mesh);
        ClassDB::bind_method(D_METHOD("set_pos", "pos"), &VoxelMesh::set_pos);
    }

public:
    VoxelMesh() { }
    ~VoxelMesh() = default;

    void set_pos(const Vector3 &pos) {
        chunk_pos = pos;
        set_global_position(pos * CHUNK_SIZE);
        UtilityFunctions::print("VoxelChunk: initialized at " + pos);
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

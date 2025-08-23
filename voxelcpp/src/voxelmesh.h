#ifndef VOXELMESH_H
#define VOXELMESH_H

#include "noisemanager.h"
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/templates/hash_set.hpp>

namespace godot {

constexpr size_t CHUNK_SIZE = 16;
constexpr size_t PADDED_SIZE = CHUNK_SIZE + 1;

class VoxelMesh : public MeshInstance3D {
	GDCLASS(VoxelMesh, MeshInstance3D)

private:
    enum class Biome {
        GRASS,
        DESERT,
        TUNDRA
    };

    // c++ knowledge: enum class won't allow implicit casts to underlying type
    enum Materials : uint16_t {
        DIRT = 0,
        GRASS = 1,
        STONE = 2,
        SAND = 3,
        SNOW = 4,
        LEAVES = 5,
        LOG = 6,
        PLANK = 7,
        WATER = 8
    };

    NoiseManager noise;
    Vector3 chunk_pos;
    float sea_level = 0.0f;
    PackedVector3Array resource_position_candidates;
    HashSet<Vector3i> destroyed_voxels;

    uint16_t voxel_materials[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0 };
    float voxel_densities[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0.0 };

    Biome get_biome(const Vector2 &pos);
    uint16_t get_material(const Vector3 &pos, float density, Biome biome);

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("generate_chunk_data"), &VoxelMesh::generate_chunk_data);
        ClassDB::bind_method(D_METHOD("generate_mesh"), &VoxelMesh::generate_mesh);
        ClassDB::bind_method(D_METHOD("set_pos", "pos"), &VoxelMesh::set_pos);
        ClassDB::bind_method(D_METHOD("get_resource_position_candidates"), &VoxelMesh::get_resource_position_candidates);
        ClassDB::bind_method(D_METHOD("delete_area", "area"), &VoxelMesh::delete_area);
        ClassDB::bind_method(D_METHOD("set_seed", "seed"), &VoxelMesh::set_seed);
        ClassDB::bind_method(D_METHOD("set_sea_level", "sea_level"), &VoxelMesh::set_sea_level);

        ADD_SIGNAL(MethodInfo("finished_mesh_generation"));
    }

public:
    VoxelMesh() { }
    ~VoxelMesh() = default;

    void set_seed(int seed) {
        noise.set_seed(seed);
    }

    void set_sea_level(float p_sea_level) { sea_level = p_sea_level; }

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

    void delete_area(const AABB& area);
};

}

#endif

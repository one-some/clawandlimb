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
    // c++ knowledge: enum class won't allow implicit casts to underlying type
    enum Materials : uint16_t {
        MATERIAL_DIRT = 0,
        MATERIAL_GRASS = 1,
        MATERIAL_STONE = 2,
        MATERIAL_SAND = 3,
        MATERIAL_SNOW = 4,
        MATERIAL_LEAVES = 5,
        MATERIAL_LOG = 6,
        MATERIAL_PLANK = 7,
        MATERIAL_WATER = 8
    };

    NoiseManager noise;
    Vector3 chunk_pos;
    float sea_level = 0.0f;
    PackedVector3Array resource_position_candidates;
    HashSet<Vector3i> destroyed_voxels;

    uint16_t voxel_materials[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0 };
    float voxel_densities[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0.0 };

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("generate_chunk_data"), &VoxelMesh::generate_chunk_data);
        ClassDB::bind_method(D_METHOD("generate_mesh"), &VoxelMesh::generate_mesh);
        ClassDB::bind_method(D_METHOD("set_pos", "pos"), &VoxelMesh::set_pos);
        ClassDB::bind_method(D_METHOD("get_resource_position_candidates"), &VoxelMesh::get_resource_position_candidates);
        ClassDB::bind_method(D_METHOD("delete_area", "area"), &VoxelMesh::delete_area);
        ClassDB::bind_method(D_METHOD("set_seed", "seed"), &VoxelMesh::set_seed);
        ClassDB::bind_method(D_METHOD("set_sea_level", "sea_level"), &VoxelMesh::set_sea_level);
        ClassDB::bind_method(D_METHOD("get_biome", "pos"), &VoxelMesh::get_biome);

        BIND_ENUM_CONSTANT(BIOME_GRASS);
        BIND_ENUM_CONSTANT(BIOME_DESERT);
        BIND_ENUM_CONSTANT(BIOME_TUNDRA);

        ADD_SIGNAL(MethodInfo("finished_mesh_generation"));
    }

public:
    VoxelMesh() { }
    ~VoxelMesh() = default;

    void set_seed(int seed) {
        noise.set_seed(seed);
    }

    enum Biome {
        BIOME_GRASS,
        BIOME_DESERT,
        BIOME_TUNDRA
    };

    uint16_t get_material(const Vector3 &pos, float density, VoxelMesh::Biome biome);
    VoxelMesh::Biome get_biome(const Vector2 &pos);

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

VARIANT_ENUM_CAST(godot::VoxelMesh::Biome);

#endif

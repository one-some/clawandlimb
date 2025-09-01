#ifndef VOXELMESH_H
#define VOXELMESH_H

#include "noisemanager.h"
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/templates/hash_set.hpp>

namespace godot {

constexpr int CHUNK_SIZE = 16;
constexpr int PADDED_SIZE = CHUNK_SIZE + 1;

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

    inline static NoiseManager* noise = nullptr;
    inline static float sea_level = 0.0f;

    Vector3 chunk_pos;
    PackedVector3Array resource_position_candidates;
    HashSet<Vector3i> destroyed_voxels;
    bool first_time_generated = true;

    uint16_t voxel_materials[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0 };
    float voxel_densities[PADDED_SIZE * PADDED_SIZE * PADDED_SIZE] = { 0.0 };

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("generate_chunk_data"), &VoxelMesh::generate_chunk_data);
        ClassDB::bind_method(D_METHOD("generate_mesh"), &VoxelMesh::generate_mesh);
        ClassDB::bind_method(D_METHOD("set_pos", "pos"), &VoxelMesh::set_pos);
        ClassDB::bind_method(D_METHOD("get_resource_position_candidates"), &VoxelMesh::get_resource_position_candidates);
        ClassDB::bind_method(D_METHOD("delete_area", "area", "soft_delete"), &VoxelMesh::delete_area);

        ClassDB::bind_static_method(get_class_static(), D_METHOD("set_seed", "seed"), &VoxelMesh::set_seed);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("set_worldgen_algorithm", "worldgen"), &VoxelMesh::set_worldgen_algorithm);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("set_sea_level", "sea_level"), &VoxelMesh::set_sea_level);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("get_biome", "pos"), &VoxelMesh::get_biome);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("sample_noise", "pos"), &VoxelMesh::sample_noise);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("find_a_good_place_to_spawn_that_player_guy"), &VoxelMesh::find_a_good_place_to_spawn_that_player_guy);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("get_chunk_size"), &VoxelMesh::get_chunk_size);

        BIND_ENUM_CONSTANT(BIOME_GRASS);
        BIND_ENUM_CONSTANT(BIOME_DESERT);
        BIND_ENUM_CONSTANT(BIOME_TUNDRA);

        BIND_ENUM_CONSTANT(WORLDGEN_FLAT);
        BIND_ENUM_CONSTANT(WORLDGEN_KITTY);

        ADD_SIGNAL(MethodInfo("finished_mesh_generation"));
        if (!noise) noise = memnew(NoiseManager);
    }

public:
    enum Biome {
        BIOME_GRASS,
        BIOME_DESERT,
        BIOME_TUNDRA
    };

    enum Worldgen {
        WORLDGEN_KITTY,
        WORLDGEN_FLAT,
    };

    inline static Worldgen worldgen_algorithm = WORLDGEN_KITTY;

    VoxelMesh() { }
    ~VoxelMesh() = default;

    static int get_chunk_size() { return CHUNK_SIZE; }

    static float sample_noise(const Vector3 &pos) {
        switch (worldgen_algorithm) {
            case WORLDGEN_FLAT:
                return 50.0f - pos.y;
            case WORLDGEN_KITTY:
            default:
                return noise->get_terrain_noise(pos);
        }
    }

    static VoxelMesh::Biome get_biome(const Vector2 &pos);

    static void set_sea_level(float p_sea_level) { sea_level = p_sea_level; }
    static void set_seed(int seed) { noise->set_seed(seed); }
    static void set_worldgen_algorithm(Worldgen p_worldgen_algorithm) { worldgen_algorithm = p_worldgen_algorithm; }

    static Vector3 find_a_good_place_to_spawn_that_player_guy() {
        for (int attempt = 0; attempt < 1000; attempt++) {
            int rand_range = 1000 * (1 + (attempt / 10));
            Vector3 point = Vector3(
                UtilityFunctions::randf() * rand_range,
                sea_level + 1.0f,
                UtilityFunctions::randf() * rand_range
            );

            float density = sample_noise(point);
            if (density < 0.0) continue;

            UtilityFunctions::print("Took ", attempt, " attempts. Now looping...");

            while (density > 0.0) {
                point.y += 1.0f;
                density = sample_noise(point);
            }

            return point;
        }

        // Sad reality
        return Vector3(0, 0, 0);
    }

    uint16_t get_material(const Vector3 &pos, float density, VoxelMesh::Biome biome);

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

    void delete_area(const AABB &area, bool soft_delete = true);
};

}

VARIANT_ENUM_CAST(godot::VoxelMesh::Biome);
VARIANT_ENUM_CAST(godot::VoxelMesh::Worldgen);

#endif

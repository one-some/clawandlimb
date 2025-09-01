#pragma once

#include "fastnoise.h"
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

class NoiseManager {
public:
    FastNoiseLite low_noise;
    FastNoiseLite high_noise;
    FastNoiseLite mountain_noise;
    FastNoiseLite detail_noise;
    FastNoiseLite cave_noise;
    FastNoiseLite rough_noise;
    FastNoiseLite biome_noise;

    NoiseManager() {
        for (const auto noise : {
            &low_noise,
            &high_noise,
            &mountain_noise,
            &detail_noise,
            &cave_noise,
            &rough_noise,
            &biome_noise
        }) {
            noise->SetNoiseType(FastNoiseLite::NoiseType_OpenSimplex2S);
            noise->SetFractalType(FastNoiseLite::FractalType_FBm);
            noise->SetFractalOctaves(5);
            noise->SetFractalLacunarity(2.0);
            noise->SetFractalGain(0.5);
        }

        low_noise.SetFractalGain(1.0);
        low_noise.SetFractalLacunarity(4.0);

        // high_noise.SetFractalOctaves(3);

        biome_noise.SetFractalOctaves(3);
        biome_noise.SetFractalGain(0.4);
        biome_noise.SetSeed(UtilityFunctions::randi());
        //low_noise.SetSeed(1337);
    }

    void set_seed(int seed) {
        int i = 0;
        for (const auto noise : {
            &low_noise,
            &high_noise,
            &mountain_noise,
            &detail_noise,
            &cave_noise,
            &rough_noise
        }) {
            noise->SetSeed(seed + i++);
        }
    }

    inline float get_noise(FastNoiseLite &noise, const Vector2 &pos) { return noise.GetNoise(pos.x, pos.y); }
    inline float get_noise(FastNoiseLite &noise, const Vector3 &pos) { return noise.GetNoise(pos.x, pos.y, pos.z); }
    inline float get_noise_norm(FastNoiseLite &noise, const Vector2 &pos) { return (get_noise(noise, pos) + 1.0) / 2.0; }
    inline float get_noise_norm(FastNoiseLite &noise, const Vector3 &pos) { return (get_noise(noise, pos) + 1.0) / 2.0; }

    inline float get_terrain_noise(const Vector3 &pos) {
        const auto v2_pos = Vector2(pos.x, pos.z);
        // 55

        float height = get_noise(low_noise, v2_pos * 0.0002) * 300.0;

        height += (
            get_noise(high_noise, v2_pos * 1.0)
            * 10.0
            * get_noise_norm(high_noise, (v2_pos + Vector2(100000, 100000)) * 0.4) // Gate
        );

        float mountain_raw = get_noise_norm(mountain_noise, v2_pos * 0.05);
        const float MOUNTAIN_THRESHOLD = 0.6f;
        if (mountain_raw > MOUNTAIN_THRESHOLD) {
            float normalized_mountain = (mountain_raw - MOUNTAIN_THRESHOLD) / (1.0f - MOUNTAIN_THRESHOLD);
            height += normalized_mountain * 200.0f;
        }


        float ravine_raw = get_noise_norm(cave_noise, (v2_pos + Vector2(100000, 100000)) * 0.8);
        const float RAVINE_THRESHOLD = 0.7f;
        if (ravine_raw > RAVINE_THRESHOLD) {
            float normalized_ravine = (ravine_raw - RAVINE_THRESHOLD) / (1.0f - RAVINE_THRESHOLD);
            height -= normalized_ravine * 200.0f;
        }

        float spaghetti_mult = get_noise_norm(cave_noise, (pos - Vector3(10000, 10000, 10000) * 0.05));
        float spaghetti = get_noise_norm(cave_noise, pos * 1.0) * spaghetti_mult;
        if (spaghetti > 0.37) {
            height = 0.0;
        }


        return height - pos.y;
    }
};

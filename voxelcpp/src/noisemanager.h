#pragma once

#include "fastnoise.h"
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

inline float smoother_step(float edge0, float edge1, float x) {
	x = godot::Math::clamp(
        (x - edge0) / godot::Math::max(0.00001f, edge1 - edge0),
        0.0f,
        1.0f
    );
	return x * x * (3.0 - 2.0 * x);
}

inline float fbm2d(
    FastNoiseLite &noise,
    const godot::Vector2 &pos,
    int octaves,
    float lacunarity,
    float gain
) {
    float sum = 0.0f;
    float amp = 1.0f;
    float freq = 1.0f;

    for (int i = 0; i < octaves; i++) {
        auto adjusted_pos = pos * freq;
        sum += noise.GetNoise(adjusted_pos.x, adjusted_pos.y) * amp;
        freq *= lacunarity;
        amp *= gain;
    }

    return sum;
}

inline float fbm3d(
    FastNoiseLite &noise,
    const godot::Vector3 &pos,
    int octaves,
    float lacunarity,
    float gain
) {
    float sum = 0.0f;
    float amp = 1.0f;
    float freq = 1.0f;

    for (int i = 0; i < octaves; i++) {
        auto adjusted_pos = pos * freq;
        sum += noise.GetNoise(adjusted_pos.x, adjusted_pos.y, adjusted_pos.z) * amp;
        freq *= lacunarity;
        amp *= gain;
    }

    return sum;
}

inline float terrace(
    float height,
    float step,
    float smoothness
) {
    if (step <= 0.0) return height;
    float i = floor(height / step);
    float frac = (height - i * step) / step;
    float sfrac = smoothness >= 1.0 ? smoother_step(0.0, 1.0, frac) : frac;
    return (i + sfrac) * step;
}

class NoiseManager {
public:
    FastNoiseLite low_noise;
    FastNoiseLite high_noise;
    FastNoiseLite mountain_noise;
    FastNoiseLite detail_noise;
    FastNoiseLite cave_noise;
    FastNoiseLite rough_noise;

    NoiseManager() {
        for (const auto noise : {
            &low_noise,
            &high_noise,
            &mountain_noise,
            &detail_noise,
            &cave_noise,
            &rough_noise
        }) {
            noise->SetNoiseType(FastNoiseLite::NoiseType_OpenSimplex2S);
            noise->SetFractalType(FastNoiseLite::FractalType_FBm);
            noise->SetFractalOctaves(5);
            noise->SetFractalLacunarity(2.0);
            noise->SetFractalGain(0.5);
        }

        low_noise.SetFractalGain(1.0);
        low_noise.SetFractalLacunarity(4.0);

        high_noise.SetFractalOctaves(3);
        //low_noise.SetSeed(1337);
    }

    void set_seed(int seed) {
        for (const auto noise : {
            &low_noise,
            &high_noise,
            &mountain_noise,
            &detail_noise,
            &cave_noise,
            &rough_noise
        }) {
            noise->SetSeed(seed);
        }
    }

    inline float get_noise(FastNoiseLite &noise, const godot::Vector2 &pos) {
        return noise.GetNoise(pos.x, pos.y);
    }

    inline float get_noise(FastNoiseLite &noise, const godot::Vector3 &pos) {
        return noise.GetNoise(pos.x, pos.y, pos.z);
    }

    inline float get_noise_3d(const godot::Vector3 &pos) {
        const auto v2_pos = godot::Vector2(pos.x, pos.z);

        float continent = get_noise(low_noise, v2_pos * 0.0009) * 80.0;

        float warp = fbm3d(high_noise, pos * 0.006, 3, 2.0, 0.5) * 20.0;
        auto pos_warp = pos + godot::Vector3(warp, warp * 0.2, -warp);

        float mountain_mask = get_noise(mountain_noise, godot::Vector2(pos_warp.x, pos_warp.z) * 0.002);
        mountain_mask = (mountain_mask + 1.0) * 0.5;
        mountain_mask = godot::Math::pow(
            godot::Math::max(0.0f, mountain_mask),
            2.5f
        );
        float mountains = mountain_mask * 120.0;

        float base_height = continent + mountains;
        base_height = terrace(base_height, 4.0, 1.0);

        //float detail = fbm3d(detail_noise, pos * 0.04, 4, 2.0, 0.5) * 58.0;
        float detail = godot::Math::pow(smoother_step(0.0f, 1.0f, get_noise(detail_noise, v2_pos * 0.4)) * 4.0f, 3.0f);

        //float cave_fbm = fbm3d(cave_noise, pos * 0.09, 4, 2.0, 0.5);
        //cave_fbm = (cave_fbm + 1.0) * 0.5;

        //const float cave_threshold = 0.62;
        //const float cave_softness = 0.08;

        //float cave_depth = smoother_step(
        //    cave_threshold - cave_softness,
        //    cave_threshold + cave_softness,
        //    cave_fbm
        //) * 18.0;

        //float density = (pos.y - base_height) - detail;//- cave_depth;
        float density = (base_height - pos.y) + detail;//- cave_depth;
        return density;
    }
};

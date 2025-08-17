#pragma once

#include "fastnoise.h"
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

class NoiseManager {
    FastNoiseLite noise;

public:
    NoiseManager() {
        noise.SetNoiseType(FastNoiseLite::NoiseType_OpenSimplex2);
        noise.SetSeed(1337);
    }

    inline float get_noise_3d(const godot::Vector3 &pos) {
        return noise.GetNoise(
            (float) pos.x,
            (float) pos.y,
            (float) pos.z
        );
    }
};
#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>

namespace godot {

class VoxelMesh : public MeshInstance3D {
	GDCLASS(VoxelMesh, MeshInstance3D)

private:
	Callable sample_noise;

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("set_sampler", "cb"), &MyExtensionClass::set_sampler);
    }

public:
	VoxelMesh();
	~VoxelMesh();

	void _process(double delta) override;

    void set_sampler(const Callable& p_sample_noise) {
        sample_noise = p_sample_noise;
    }
};

}

#endif

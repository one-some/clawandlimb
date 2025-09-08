#pragma once

#include "voxelmesh.h"
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/templates/hash_set.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

class ChunkJob : public RefCounted {
	GDCLASS(ChunkJob, RefCounted)

public:
    enum ChunkJobState {
        STATE_PENDING,
        STATE_WORKING,
        STATE_DONE
    };

    struct JobScoreComparator {
        bool operator()(Ref<ChunkJob> a, Ref<ChunkJob> b) const {
            return a->score > b->score;
        }
    };

    Vector3i chunk_position;
    float score = 0.0;
    Callable heavy_lifting;
    ChunkJobState state = STATE_PENDING;

    inline static Vector<Ref<ChunkJob>> chunk_job_queue = { };

    ChunkJob() { };
    ~ChunkJob() = default;

    bool operator==(const ChunkJob& that) const {
        return chunk_position == that.chunk_position;
    }

    void set_position(const Vector3i& p_chunk_position) {
        chunk_position = p_chunk_position;
    }

    void set_heavy_lifting(const Callable& p_heavy_lifting) {
        heavy_lifting = p_heavy_lifting;
    }

    static inline bool is_pos_in_queue(const Vector3i& pos) {
        for (auto& chunk_job : chunk_job_queue) {
            if (pos == chunk_job->chunk_position) return true;
        }
        return false;
    }

    static inline Ref<ChunkJob> pop_best_chunk() {
        Ref<ChunkJob> job;
        
        while (true) {
            job = chunk_job_queue.get(0);

            if (!job.is_null()) {
                chunk_job_queue.remove_at(0);
            } else {
                break;
            }

            if (job->state != STATE_PENDING) continue;
            job->state = STATE_WORKING;
            break;
        }

        return job;
    }

    void do_heavy_lifting() {
        heavy_lifting.call();
        // Can we do this without locking mutex?
        // state = STATE_DONE;
    }

    void add_to_queue() {
        if (ChunkJob::is_pos_in_queue(this->chunk_position)) return;
        chunk_job_queue.push_back(Ref<ChunkJob>(this));
    }

    static inline void sort_queue() {
        chunk_job_queue.sort_custom<JobScoreComparator>();
    }

    static inline void update_queue_scores(Vector3 generation_origin, Camera3D* cam) {
        for (auto& chunk_job : chunk_job_queue) {
            chunk_job->update_score(generation_origin, cam);
        }
    }

    void update_score(Vector3 generation_origin, Camera3D* cam) {
        Vector3 chunk_origin = Vector3(chunk_position) * CHUNK_SIZE;
		float half_size = CHUNK_SIZE * 0.5f;
		
		Vector3 center = chunk_origin + Vector3(half_size, half_size, half_size);
		Vector3 top_center = chunk_origin + Vector3(half_size, CHUNK_SIZE, half_size);
		
		float dist_sq = generation_origin.distance_squared_to(center);
		float base_score = 1.0f / (dist_sq + 1.0f);

		int visible_count = 0;
		if (cam->is_position_in_frustum(center)) {
			visible_count += 1;
        } else if (cam->is_position_in_frustum(top_center)) {
			visible_count += 1;
        }

		float visibility_ratio = (float)visible_count / 2.0f;
		float visibility_bonus = 1.0f + (visibility_ratio * 0.4f);

		Vector3 dir = center - cam->get_global_transform().origin;
		float inv_len = 1.0f / Math::sqrt(Math::max(1e-6f, dir.length_squared()));
		float facing_factor = Math::clamp(-cam->get_global_transform().basis.rows[2].dot(dir) * inv_len, 0.0f, 1.0f);

		score = base_score * visibility_bonus * (1.0f + facing_factor * 0.35f);
    }

protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("set_position", "chunk_position"), &ChunkJob::set_position);
        ClassDB::bind_method(D_METHOD("set_heavy_lifting", "callback"), &ChunkJob::set_heavy_lifting);
        ClassDB::bind_method(D_METHOD("update_score", "generation_origin", "cam"), &ChunkJob::update_score);
        ClassDB::bind_method(D_METHOD("do_heavy_lifting"), &ChunkJob::do_heavy_lifting);
        ClassDB::bind_method(D_METHOD("add_to_queue"), &ChunkJob::add_to_queue);

        ClassDB::bind_static_method(get_class_static(), D_METHOD("is_pos_in_queue", "pos"), &ChunkJob::is_pos_in_queue);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("pop_best_chunk"), &ChunkJob::pop_best_chunk);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("update_queue_scores", "generation_origin", "cam"), &ChunkJob::update_queue_scores);
        ClassDB::bind_static_method(get_class_static(), D_METHOD("sort_queue"), &ChunkJob::sort_queue);

        BIND_ENUM_CONSTANT(STATE_PENDING);
        BIND_ENUM_CONSTANT(STATE_WORKING);
        BIND_ENUM_CONSTANT(STATE_DONE);
    }

};

}

VARIANT_ENUM_CAST(godot::ChunkJob::ChunkJobState);
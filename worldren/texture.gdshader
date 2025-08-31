shader_type spatial;

uniform sampler2DArray textures : filter_nearest, source_color;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec4 mat_weights;
varying flat vec4 mat_ids;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (inverse(transpose(MODEL_MATRIX)) * vec4(NORMAL, 0.0)).xyz;

	mat_weights = COLOR;
	mat_ids = CUSTOM0 * 255.0;
}

vec4 triplanar_sample(float id, vec3 pos, vec3 norm) {
	float layer = floor(id);
	//pos *= 5.0;

	vec4 x_tex = texture(textures, vec3(pos.zy, layer));
	vec4 y_tex = texture(textures, vec3(pos.xz, layer));
	vec4 z_tex = texture(textures, vec3(pos.xy, layer));

	vec3 weights = abs(norm);
	weights /= (weights.x + weights.y + weights.z);

	return (x_tex * weights.x) + (y_tex * weights.y) + (z_tex * weights.z);
}

void fragment() {
	vec4 final_color = vec4(0.0, 0.0, 0.0, 1.0);

	final_color += triplanar_sample(mat_ids.x, world_pos, world_normal) * mat_weights.x;
	final_color += triplanar_sample(mat_ids.y, world_pos, world_normal) * mat_weights.y;
	final_color += triplanar_sample(mat_ids.z, world_pos, world_normal) * mat_weights.z;
	final_color += triplanar_sample(mat_ids.w, world_pos, world_normal) * mat_weights.w;

	ALBEDO = final_color.rgb;
}
shader_type spatial;

uniform sampler2DArray textures : filter_nearest, source_color;

varying vec3 world_pos;
varying flat vec4 material_ids;
varying vec2 blend_uv;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	material_ids = COLOR;
	blend_uv = UV2;
}

void fragment() {
	vec3 weights = abs(NORMAL);
	weights /= (weights.x + weights.y + weights.z);
	
    float material_id_a = round(material_ids.r * 255.0);
    float material_id_b = round(material_ids.g * 255.0);
	float mat_weight = blend_uv.x;
	
	vec4 x_tex_a = texture(textures, vec3(world_pos.zy, material_id_a));
	vec4 y_tex_a = texture(textures, vec3(world_pos.xz, material_id_a));
	vec4 z_tex_a = texture(textures, vec3(world_pos.xy, material_id_a));
	vec4 color_a = (x_tex_a * weights.x) + (y_tex_a * weights.y) + (z_tex_a * weights.z);
	
	
	vec4 x_tex_b = texture(textures, vec3(world_pos.zy, material_id_b));
	vec4 y_tex_b = texture(textures, vec3(world_pos.xz, material_id_b));
	vec4 z_tex_b = texture(textures, vec3(world_pos.xy, material_id_b));
	vec4 color_b = (x_tex_b * weights.x) + (y_tex_b * weights.y) + (z_tex_b * weights.z);
	
	vec4 final_color = mix(color_a, color_b, mat_weight);
	
	ALBEDO = final_color.rgb;
}
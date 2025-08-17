extends Node

var tree_grid = {}

var low_noise = FastNoiseLite.new()
var high_noise = FastNoiseLite.new()
var mountain_noise = FastNoiseLite.new()
var detail_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()
var rough_noise = FastNoiseLite.new()

func _ready() -> void:
	low_noise.fractal_lacunarity = 4.0
	low_noise.fractal_gain = 1.0
	high_noise.fractal_octaves = 3

func smootherstep(edge0: float, edge1: float, x: float) -> float:
	x = clamp((x - edge0) / max(0.00001, edge1 - edge0), 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func fbm2d(noise, p: Vector2, octaves: int, lacunarity: float, gain: float) -> float:
	var sum = 0.0
	var amp = 1.0
	var freq = 1.0
	for i in range(octaves):
		sum += noise.get_noise_2dv(p * freq) * amp
		freq *= lacunarity
		amp *= gain
	return sum

func fbm3d(noise, p: Vector3, octaves: int, lacunarity: float, gain: float) -> float:
	var sum = 0.0
	var amp = 1.0
	var freq = 1.0
	for i in range(octaves):
		sum += noise.get_noise_3dv(p * freq) * amp
		freq *= lacunarity
		amp *= gain
	return sum

func terrace(height: float, step: float, smoothness: float) -> float:
	if step <= 0.0:
		return height
	var i = floor(height / step)
	var frac = (height - i * step) / step
	var sfrac = smootherstep(0.0, 1.0, frac) if smoothness >= 1.0 else frac
	return (i + sfrac) * step

# Main sample_noise replacement
func sample_noise(pos: Vector3) -> float:
	var v2_pos = Vector2(pos.x, pos.z)
	var continent = low_noise.get_noise_2dv(v2_pos * 0.0009) * 80.0

	var warp = fbm3d(high_noise, pos * 0.006, 3, 2.0, 0.5) * 20.0
	var pos_warp = pos + Vector3(warp, warp * 0.2, -warp)

	var mountain_mask = mountain_noise.get_noise_2dv(Vector2(pos_warp.x, pos_warp.z) * 0.002)
	mountain_mask = (mountain_mask + 1.0) * 0.5
	mountain_mask = pow(max(0.0, mountain_mask), 2.5)
	var mountains = mountain_mask * 120.0

	var base_height = continent + mountains
	base_height = terrace(base_height, 4.0, 1.0)

	var detail = fbm3d(detail_noise, pos * 0.04, 4, 2.0, 0.5) * 8.0

	var cave_fbm = fbm3d(cave_noise, pos * 0.09, 4, 2.0, 0.5)
	cave_fbm = (cave_fbm + 1.0) * 0.5
	var cave_threshold = 0.62
	var cave_softness = 0.08
	var cave_mask = smootherstep(cave_threshold - cave_softness, cave_threshold + cave_softness, cave_fbm)
	var cave_depth = cave_mask * 18.0

	var density = (base_height - pos.y) + detail - cave_depth
	print(density)
	return density

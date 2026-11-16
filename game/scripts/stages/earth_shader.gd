class_name EarthShader
extends RefCounted
## A cheap procedural Earth for the moon sky: a lit, slowly turning globe with oceans, land,
## ice caps, clouds and an atmosphere rim, drawn by a canvas_item shader on one small quad.

const CODE := """
shader_type canvas_item;

uniform sampler2D land_tex : repeat_enable, filter_linear;
uniform sampler2D cloud_tex : repeat_enable, filter_linear;
uniform vec2 light_dir = vec2(0.75, -0.3);
uniform float spin = 0.006;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float edge = 1.0 - smoothstep(0.97, 1.0, r);
	float z = sqrt(max(1.0 - r * r, 0.0));
	float lon = atan(p.x, z) / 3.14159265;
	float lat = asin(clamp(-p.y, -1.0, 1.0)) / 3.14159265;
	vec2 uv = vec2(lon * 0.5 + TIME * spin, lat * 0.9 + 0.5);
	float land = texture(land_tex, uv).r;
	float cloud = texture(cloud_tex, uv * vec2(1.0, 1.2) + vec2(TIME * spin * 1.7, 0.0)).r;
	float is_land = smoothstep(0.5, 0.54, land);
	vec3 ocean = mix(vec3(0.05, 0.22, 0.52), vec3(0.1, 0.38, 0.72), smoothstep(0.35, 0.5, land));
	vec3 ground = mix(vec3(0.2, 0.46, 0.2), vec3(0.62, 0.55, 0.3), smoothstep(0.55, 0.75, land));
	vec3 col = mix(ocean, ground, is_land);
	col = mix(col, vec3(0.93, 0.97, 1.0), smoothstep(0.72, 0.86, abs(lat * 2.0)));
	col = mix(col, vec3(1.0), smoothstep(0.58, 0.92, cloud) * 0.7);
	vec3 n = vec3(p, z);
	float lit = smoothstep(-0.12, 0.5, dot(n, normalize(vec3(light_dir, 0.45))));
	col *= mix(0.07, 1.0, lit);
	col += vec3(0.3, 0.55, 1.0) * pow(1.0 - z, 2.4) * (0.2 + 0.8 * lit);
	COLOR = vec4(col, edge);
}
"""


static func make_material(seed_value: int) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("land_tex", _noise_texture(seed_value, 4, 0.045))
	material.set_shader_parameter("cloud_tex", _noise_texture(seed_value + 11, 5, 0.07))
	return material


static func _noise_texture(seed_value: int, octaves: int, frequency: float) -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	noise.frequency = frequency
	return ImageTexture.create_from_image(noise.get_seamless_image(128, 128))

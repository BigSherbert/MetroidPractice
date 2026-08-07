shader_type canvas_item;

uniform float HitShaderMix : hint_range(0.0, 1.0) = 1.0;
uniform vec4 HitShaderColor : source_color = vec4(1.0, 0.92, 0.25, 1.0);
uniform float RainbowAmount : hint_range(0.0, 1.0) = 0.62;
uniform float RainbowSpeed : hint_range(0.0, 2.0) = 0.22;
uniform float RainbowScale : hint_range(0.1, 4.0) = 1.15;
uniform float PulseStrength : hint_range(0.0, 0.5) = 0.08;

vec3 hsv_to_rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 0.6666667, 0.3333333)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float hue = fract((UV.x * 0.72 + UV.y * 0.38) * RainbowScale + TIME * RainbowSpeed);
	vec3 rainbow = hsv_to_rgb(vec3(hue, 0.82, 1.0));
	vec3 energized = tex.rgb * mix(vec3(1.0), vec3(0.78) + rainbow * 0.72, RainbowAmount);
	float pulse = 1.0 + sin(TIME * 3.5) * PulseStrength;
	vec4 colorful = vec4(energized * pulse, tex.a);
	vec3 final_color = mix(HitShaderColor.rgb, colorful.rgb, HitShaderMix);
	COLOR = vec4(final_color, tex.a);
}

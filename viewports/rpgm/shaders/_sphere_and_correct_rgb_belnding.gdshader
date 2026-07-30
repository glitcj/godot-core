shader_type canvas_item;
render_mode blend_mix;

uniform float progress   : hint_range(0.0, 1.0)   = 0.0;
uniform vec4  tint       : source_color            = vec4(1.0, 0.5, 1.0, 1.0);
uniform float wave_amp   : hint_range(0.0, 0.1)   = 0.03;
uniform float wave_freq  : hint_range(1.0, 20.0)  = 8.0;
uniform float wave_phase : hint_range(0.0, 100.0) = 10.0;
uniform float frame_size : hint_range(0.0, 1028.0) = 48.0;
uniform bool vertex_warp;
uniform bool fragment_warp;

// --- Add these ---
uniform sampler2D noise_tex;                              // assign a NoiseTexture2D here
uniform float noise_scale  : hint_range(0.1, 5.0) = 1.0; // zoom level of noise
uniform float noise_speed  : hint_range(0.0, 2.0) = 0.2; // scroll speed
uniform float noise_strength : hint_range(0.0, 1.0) = 0.4; // how visible the noise is

void vertex() {}

void fragment() {
    float inner_circle  = step(0.8, distance(vec2(0.5), UV) * 2.0);
    float outer_circle  = step(1.0, distance(vec2(0.5), UV) * 2.0);
    float gradient_circle = smoothstep(0.4, 0.55, distance(vec2(0.5), UV));
    float spherish = (inner_circle - outer_circle) * gradient_circle;
	
	vec2 noise_uv = vec2(TIME * noise_speed, TIME * noise_speed * 0.7);
	
	float noise = texture(noise_tex, fract(UV + noise_uv)).r;
    vec4 tex = texture(TEXTURE, UV);

    // colorize: blend between dark tint and bright tint based on noise
    vec4 noise_color = mix(tint * .5, tint, noise);

	
	if (false){
	vec4 sphere = vec4(tint.rgb * (0.5 + noise * 0.3), spherish);
	COLOR = mix(sphere, tex, tex.a);
	}
	
	else {
		vec4 sphere = vec4(tint.rgb * (0.5 + noise * 0.3), spherish * noise_strength);

		vec3 blended = mix(tex.rgb, sphere.rgb, sphere.a); // sphere over character
		COLOR.rgb = mix(sphere.rgb, blended, tex.a);        // where tex is transparent, skip the blend and just show sphere directly
		COLOR.a = max(tex.a, sphere.a) * 2.;
	}

}
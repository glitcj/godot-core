shader_type canvas_item;
render_mode blend_mix;

uniform float progress   : hint_range(0.0, 1.0)   = 0.0;
uniform vec4  tint       : source_color            = vec4(1.0, 0.5, 1.0, 1.0);
uniform float wave_amp   : hint_range(0.0, 0.1)   = 0.03;
uniform float wave_freq  : hint_range(1.0, 20.0)  = 8.0;
uniform float wave_phase : hint_range(0.0, 100.0) = 10.0;
uniform float frame_size : hint_range(0.0, 1028.0) = 48.0;

uniform float outline_width : hint_range(0.0, 0.5) = 0.03;

uniform bool run_vertex;
uniform bool run_fragment;

// --- Add these ---
uniform sampler2D noise_tex;                              // assign a NoiseTexture2D here
uniform float noise_scale  : hint_range(0.1, 5.0) = 1.0; // zoom level of noise
uniform float noise_speed  : hint_range(0.0, 2.0) = 0.2; // scroll speed
uniform float noise_strength : hint_range(0.0, 1.0) = 0.4; // how visible the noise is


uniform bool time_as_progress = true ;

void vertex() {}

void fragment() {
	float _progress ;
	if (time_as_progress) _progress = TIME ;
	vec4 tex = texture(TEXTURE, UV) ;
	
	vec4 outlined ;
	vec4 smudged_left = texture(TEXTURE, UV + vec2(+outline_width, 0.0)) ;
	vec4 smudged_right = texture(TEXTURE, UV + vec2(-outline_width, 0.0)) ;
	vec4 smudged_up = texture(TEXTURE, UV + vec2(0., outline_width)) ;
	vec4 smudged_down = texture(TEXTURE, UV + vec2(0., -outline_width)) ;
	
	outlined = mix(tex, smudged_left,  step(0.00001, smudged_left.a - tex.a)) ;
	outlined = mix(outlined, smudged_right,  step(0.00001, smudged_right.a - tex.a)) ;
	outlined = mix(outlined, smudged_up,  step(0.00001, smudged_up.a - tex.a)) ;
	outlined = mix(outlined, smudged_down,  step(0.00001, smudged_down.a - tex.a)) ;
	
	outlined.rgb = mix(tex.rgb, vec3(1.,1.,1.),  1. - tex.a) ;
	outlined.rgb = mix(tex.rgb, vec3(sin(UV + vec2(sin(_progress))), UV.x/2.),  1. - tex.a) ;
	
	COLOR = outlined;
}


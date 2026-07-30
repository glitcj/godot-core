shader_type canvas_item;
render_mode blend_mix;
uniform float progress   : hint_range(0.0, 1.0)   = 0.0;
uniform vec4  tint       : source_color            = vec4(1.0, 0.5, 1.0, 1.0);
uniform float wave_amp   : hint_range(0.0, 0.1)   = 0.03;
uniform float wave_freq  : hint_range(1.0, 20.0)  = 8.0;
uniform float wave_phase : hint_range(0.0, 100.0) = 10.0;
uniform float frame_size : hint_range(0.0, 1028.0) = 48.0;
uniform bool run_vertex;
uniform bool run_fragment; // uniform bools are safe to branch on — same value for every fragment, whole warp takes the same path, no divergence
uniform sampler2D noise_tex;
uniform float noise_scale  : hint_range(0.1, 5.0) = 1.0;
uniform float noise_speed  : hint_range(0.0, 2.0) = 0.2;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.4;
uniform bool time_as_progress = true ;
uniform float speed: hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float angle : hint_range(0.0, 3.14 * 2., 0.0) = 0.0 ;

void vertex() {}
void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec4 pixel = vec4(0.) ;
	vec4 noxel ;
	vec2 centered_uv = UV * 2. - 1. ;
	vec2 cartesian_uv = vec2(centered_uv.x, -centered_uv.y ) ;
	
	// Using ifs on uniform variables is GPU friendly, because all pixels will follow exactly the same instruction path.
	if (!run_fragment) { 
		vec4 noxel_octave_1 = texture(noise_tex, vec2( fract(UV.x + TIME / (1./speed)) , UV.y));
		vec4 noxel_octave_2 = texture(noise_tex, vec2( fract(UV.x + TIME / (1./speed)) , fract(UV.y + .5) ));
		noxel = noxel_octave_1 ;
		
		float slope = 1. ;
		// no divergence here — every fragment runs the same multiply, just with a different value of centered_uv.x
		// divergence is about which instructions run, not what values they produce
		// float function_at_x = slope * cartesian_uv.x ;
		// float function_at_x = sin(5. * cartesian_uv.x) ;
		float function_at_x = tan(cartesian_uv.x) ;
		
		// float function_at_x = -1. - tan(cartesian_uv.x) * 1. ;
		// float function_at_x = cartesian_uv.x ;
		
		pixel.a = 1. ;
		// ⚠ this if causes warp divergence — fragments near the line take a different code path than fragments far from it
		// the GPU runs both sides of the branch for the whole warp and masks out the irrelevant results, wasting work
		// branchless equivalent: pixel.rgb = vec3(1.0 - step(0.02, abs(centered_uv.y - function_at_x)));
		// or with smooth anti-aliased edge: pixel.rgb = vec3(1.0 - smoothstep(0.01, 0.02, abs(centered_uv.y - function_at_x)));
		// step/smoothstep convert the distance into a value — same instruction for every fragment, no split code paths
		// if (abs(centered_uv.y - function_at_x) < 0.02) pixel.rgb = vec3(1.) ;


		// ⚠ divergent — fragments split into two code paths, GPU runs both and masks results
		// if (abs(centered_uv.y - function_at_x) < 0.02) pixel.rgb = vec3(1.) ;
		// branchless — distance becomes a value, one instruction stream for all fragments
		pixel.rgb = vec3(1.0 - smoothstep(0.01, 0.02, abs(cartesian_uv.y - function_at_x)));
	}
	COLOR = pixel ;
}
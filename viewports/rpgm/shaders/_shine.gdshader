shader_type canvas_item;
render_mode blend_mix;

uniform float progress   : hint_range(0.0, 1.0)   = 0.0;
uniform vec4  tint       : source_color            = vec4(1.0, 0.5, 1.0, 1.0);
uniform float wave_amp   : hint_range(0.0, 0.1)   = 0.03;
uniform float wave_freq  : hint_range(1.0, 20.0)  = 8.0;
uniform float wave_phase : hint_range(0.0, 100.0) = 10.0;
uniform float frame_size : hint_range(0.0, 1028.0) = 48.0;

uniform bool run_vertex;
uniform bool run_fragment;

// --- Add these ---
uniform sampler2D noise_tex;                              // assign a NoiseTexture2D here
uniform float noise_scale  : hint_range(0.1, 5.0) = 1.0; // zoom level of noise
uniform float noise_speed  : hint_range(0.0, 2.0) = 0.2; // scroll speed
uniform float noise_strength : hint_range(0.0, 1.0) = 0.4; // how visible the noise is

uniform bool time_as_progress = true ;
uniform float speed: hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float angle : hint_range(0.0, 3.14 * 2., 0.0) = 0.0 ;

void vertex() {}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec4 pixel = vec4(1.) ;
	vec4 noxel ;
	vec2 centered_uv = UV * 2. - 1. ;
	
	vec4 noxel_octave_1 =  texture(noise_tex, vec2(  fract(UV.x + TIME / (1./speed)) , UV.y));
	vec4 noxel_octave_2 =  texture(noise_tex, vec2(  fract(UV.x + TIME / (1./speed)) , fract(UV.y + .5)  ));
	noxel = noxel_octave_1 ; // + noxel_octave_2
	
	float slope = tan(angle) ;
	
	// pixel.rgb = vec3(centered_uv.y -  slope * centered_uv.x) ;
	// float function_at_x = slope * centered_uv.x ;
	
	float function_at_x = sin(UV.x * 32.) * .5 ;
	
	// pixel.rgb = mix(vec3(0.), vec3(1.), step(0.3, centered_uv.y - function_at_x) ) ;
	// pixel.rgb = mix(vec3(0.), vec3(1.), centered_uv.y - function_at_x) ;
	
	// pixel.rgb = vec3(centered_uv.y - slope * centered_uv.x) ;
	// pixel.rgb = vec3(centered_uv.y -  slope * centered_uv.x ) ;
	
	// Notice that the following two lines are the same equation:
	// pixel.rgb = mix(vec3(0.), vec3(1.), centered_uv.y - function_at_x) ;
	// pixel.rgb = vec3(centered_uv.y -  slope * centered_uv.x ) ;
	pixel.rgb = vec3(centered_uv.y -  function_at_x ) ;
	// the first one can be expanded to:
	// ( 0. * (centered_uv.y - function_at_x) + 1. * (centered_uv.y - function_at_x) )
	// which equals (centered_uv.y - function_at_x)
	// which equals (centered_uv.y - slope * centered_uv.x)
	
	// Therefore an easy to read:
	// pixel.rgb = (centered_uv.y - slope * centered_uv.x)
	// Is that the pixel color shows the distance between Y and 
	// the disired function to plot over X
	
	
	// In summary:
	// (centered_uv.y - function_at_x)
	// Equals:
	// mix(vec(0.), vec(1.), centered_uv.y - function_at_x) ;
	// In other words, pixel = (centered_uv.y - f(x)) is a general way of plotting f(x)
	
	// Just somee random notes while solving the above:
	// pixel is 1. when: y = slope * x
	// pixel is not 1. when: y != slope * x
	
	// pixel.rgb = vec3(UV.y -  UV.x ) ;
	// pixel.rgb = step(0.2, pixel.rgb) ;
	// pixel.rgb = vec3(centered_uv.y) ;
	
	// at angle = 0, slope = tan(0) = 0
	// at UV.x = -1 (-1 - (-1)) to (+1 - (-1))
	// at UV.x = +1 (-1 - (+1)) to (+1 - (+1))
	
	// at angle = PI/2, slope = tan(PI/2) = inf
	// at UV.x = -1, (-1 - (-1 * inf)) to (+1 - (-1 * inf))
	// at UV.x = +1, (-1 - (+1 * inf)) to (+1 - (+1 * inf))
	
	// tan is the ratio of the opposite line to adjacent line, as you trace a circle
	// tan is the slope of the line touching the circle at angle theta
	
	COLOR = pixel ;
}


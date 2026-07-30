shader_type canvas_item;
render_mode blend_mix;

// Declared with 'varying' so the GPU bilinearly interpolates this value
// across all fragments between the vertices set in vertex().
// You set the anchor value at each vertex; the GPU fills in everything between.
varying vec2 varying_vertex_position;
varying vec2 varying_world_position;
varying vec2 varying_canvas_position;  // canvas pixel space, interpolated
varying vec2 varying_screen_position;  // screen NDC space, interpolated

uniform vec2 circle_center = vec2(0.,0.);

void vertex() {
	// set new anchor of varying_vertex_position as this VERTEX
	varying_vertex_position = VERTEX;
	
	// set new anchor of varying_world_position as this (MODEL_MATRIX * vec4(VERTEX, 0., 1.)).xy
	varying_world_position = (MODEL_MATRIX * vec4(VERTEX, 0., 1.)).xy ;
	
	// set more anchors
	varying_canvas_position = (CANVAS_MATRIX * MODEL_MATRIX * vec4(VERTEX, 0., 1.)).xy;
	varying_screen_position = (SCREEN_MATRIX * CANVAS_MATRIX * MODEL_MATRIX * vec4(VERTEX, 0., 1.)).xy;
	
	// GPU will use anchors to calculate varying values for each fragment
	// Note that the "=" sign is overriden for variables defined with varying keyword
	// So = is NOT assignment, it is a function that sets an anchor for the defined varying variable
}

void fragment() {
	// COLOR.rg = varying_world_position ;
	// COLOR.rg = varying_vertex_position ;
	// COLOR.a = varying_vertex_position.x ;
	// COLOR.a = step(0., varying_world_position.x) ;
	
	float interpolator = step(1., distance(varying_world_position, circle_center) / 100.) ;
	COLOR.rgb = mix(vec3(1., 0., 0.), texture(TEXTURE, UV).rgb,  interpolator ) ;
	
	
	
	// UV — normalized texture space (0,0)→(1,1), same as UV in vertex(), interpolated across fragments
	//   use this for texture sampling
	// COLOR = texture(TEXTURE, UV);

	// TEXTURE_PIXEL_SIZE — vec2(1/texture_width, 1/texture_height)
	//   multiply UV by (1./TEXTURE_PIXEL_SIZE) to get pixel position within the texture
	// COLOR.rg = UV * (1. / TEXTURE_PIXEL_SIZE) / 48.; // visualise, normalised for a 48px texture

	// varying_local_position — local pixel space, interpolated from vertex() anchors
	//   same space as VERTEX in vertex(): (-24,-24)→(24,24) for a 48x48 centered sprite
	// COLOR.rg = (varying_local_position + 24.) / 48.; // shift and normalise to 0-1 for visualisation

	// varying_world_position — world pixel space, interpolated from vertex() anchors
	//   a node at scene position (500,300) has world positions offset by (500,300)
	// COLOR.rg = varying_world_position / 1028.; // normalise to 0-1 for a 1028px scene

	// varying_canvas_position — canvas pixel space, interpolated from vertex() anchors
	//   accounts for camera transform; panning the camera shifts these values
	// COLOR.rg = varying_canvas_position / 1028.;

	// varying_screen_position — screen NDC space, interpolated from vertex() anchors
	//   ranges roughly (-1,-1)→(1,1); centre of screen = (0,0)
	// COLOR.rg = varying_screen_position * 0.5 + 0.5; // remap to 0-1 for visualisation

	// VERTEX in fragment() — screen pixel space (COMPLETELY DIFFERENT from VERTEX in vertex()!)
	//   ranges from (0,0) to (viewport_width, viewport_height), origin top-left
	// COLOR.rg = VERTEX / vec2(1028., 1028.);

	// FRAGCOORD — also screen pixel space, but vec4(x, y, depth, 1/w)
	//   xy should match VERTEX in fragment() for canvas_item shaders
	//   z = depth (0→1), w = 1/clip_w
	//   caution: FRAGCOORD.y may use bottom-left origin (OpenGL convention) — verify if y appears flipped vs VERTEX
	// COLOR.rg = FRAGCOORD.xy / vec2(1028., 1028.);

	// SCREEN_UV — normalized screen space (0,0)→(1,1)
	//   equivalent to VERTEX / viewport_size but pre-computed; useful for sampling SCREEN_TEXTURE
	// COLOR.rg = SCREEN_UV;
}
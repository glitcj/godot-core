shader_type canvas_item;
render_mode blend_mix;

varying vec2 screen_position ;

void vertex() {
	screen_position = (CANVAS_MATRIX * MODEL_MATRIX * vec4(VERTEX, 0, 1)).xy ;
}

void fragment() {
	// all the 4 vectors below are equivalent
	vec2 screen_uv_via_canvas_matrix = screen_position * SCREEN_PIXEL_SIZE ; 
	vec2 screen_uv_via_fragment_vertex = VERTEX * SCREEN_PIXEL_SIZE ;
	vec2 screen_uv_via_fragment_screen_uv = SCREEN_UV ;
	vec2 screen_uv_via_fragment_fragcord = FRAGCOORD.xy ;
}
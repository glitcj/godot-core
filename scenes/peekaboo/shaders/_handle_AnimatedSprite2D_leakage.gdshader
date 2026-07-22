shader_type canvas_item;

uniform float progress   : hint_range(0.0, 1.0)   = 0.0;
uniform vec4  tint       : source_color            = vec4(1.0, 0.0, 0.0, 1.0);
uniform float wave_amp   : hint_range(0.0, 0.1)   = 0.03;
uniform float wave_freq  : hint_range(1.0, 20.0)  = 8.0;
uniform float wave_phase : hint_range(0.0, 100.0) = 10.0;
uniform float frame_size : hint_range(0.0, 1028.0) = 48.0; // pixel width/height of one frame

uniform bool vertex_warp;
uniform bool fragment_warp;


/* Weird shake.
void weird_shake(vec2 _vertex) {
	vec2 symmetrical_vertex = _vertex * 2.0 - 1.0;
	_vertex.x += sin(TIME * symmetrical_vertex.x / 10.) * 2.0;
	_vertex.y += sin(TIME * symmetrical_vertex.y / 10.) * 2.0;
}
*/

/* Kind of of swimming.
void vertex() {
	vec2 symmetrical_vertex = VERTEX * 2.0 - 1.0;
	VERTEX.x += sin(TIME * UV.y) * 20.0;
	VERTEX.y += cos(TIME * UV.y) * 20.0;
}
*/

void vertex() {
	VERTEX.x += sin(TIME + PI) * 25.0 * (1. - UV.y)  +  sin(TIME) * 25.0 * (UV.y) ;
}

void fragment() {
    // size of one frame in UV space — derived from the texture, no frame_index needed
    vec2 frame_uv_size = TEXTURE_PIXEL_SIZE * frame_size;

    // floor snaps UV down to the nearest frame boundary
    // this gives us the top-left corner of whichever frame this pixel is in
    vec2 frame_min = floor(UV / frame_uv_size) * frame_uv_size;
    vec2 frame_max = frame_min + frame_uv_size;

    vec2 warped = UV;
    warped.x += sin(UV.y * wave_freq + TIME * 4.0) * wave_amp;
    warped = clamp(warped, frame_min, frame_max);

    vec4 tex = texture(TEXTURE, warped);
	if (!fragment_warp) tex = texture(TEXTURE, UV);
	
	COLOR.rgb = tex.rgb;
    COLOR.a = tex.a;
}
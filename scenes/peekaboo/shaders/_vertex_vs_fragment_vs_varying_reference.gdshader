shader_type canvas_item;
render_mode blend_mix;

// Declared with 'varying' so the GPU bilinearly interpolates this value
// across all fragments between the vertices set in vertex().
// You set the anchor value at each vertex; the GPU fills in everything between.
varying vec2 varying_vertex;

void vertex() {
	// vertex() runs once per vertex.
	//
	// VERTEX: the vertex position in LOCAL PIXEL SPACE, centered on the node origin.
	//   e.g. a 48x48 Sprite2D has corners at (-24,-24), (24,-24), (-24,24), (24,24).
	//   Scaling the sprite scales these values proportionally.
	//
	// VERTEX changes does NOT persist across frames. Each frame it is reset to the original
	//   mesh vertex position before vertex() runs. Animations must be driven by TIME
	//   or a uniform — you cannot accumulate changes by doing VERTEX += delta.
	//
	// COLOR in vertex(): a modulate multiplier applied to the final fragment colour,
	//   NOT the absolute pixel colour. Writing COLOR.r = 0.5 tints all fragments red by 50%.

	VERTEX.x += sin(UV.y * 10. + TIME) * 1.;

	// What it looks like:
	//   varying_vertex = VERTEX;
	// What it conceptually means:
	//   set_vertex_value_for_gpu_to_interpolate(varying_vertex, VERTEX);
	//
	// This runs once per vertex, setting that vertex's anchor value.
	// The GPU then interpolates varying_vertex across every fragment between those anchors.
	// A fragment at the center of a 48x48 sprite receives (0,0); a corner receives e.g. (-24,-24).
	varying_vertex = VERTEX;
}

void fragment() {
	// fragment() runs once per pixel covered by the mesh.
	//
	// VERTEX in fragment(): the fragment's position in SCREEN PIXEL SPACE.
	//   e.g. on a 1028x1028 viewport this ranges from (0,0) to (1028,1028).
	//   This is a completely different space from VERTEX in vertex().
	//
	// varying_vertex in fragment(): the interpolated vertex position in LOCAL PIXEL SPACE
	//   (same space as VERTEX in vertex()). For a 48x48 centered sprite this ranges
	//   from (-24,-24) to (24,24). Useful for effects that should be relative to the
	//   sprite's own size rather than the screen.
	//
	// COLOR in fragment(): the absolute pixel colour written to the screen.

	COLOR.rg = varying_vertex;
	// Dending on the texture size, the colors might look like they are 0 or 1, 
	// but actually thats just because the scale of varying_vertex is in pixel space
	// while the scale of RGB is in [0, 1]

	// Normalise to 0..1 range before assigning to COLOR channels:
	// COLOR.rg = varying_vertex / (1. / TEXTURE_PIXEL_SIZE); // using local space
	// COLOR.rg = VERTEX        / (1. / TEXTURE_PIXEL_SIZE); // using screen space — will differ
}
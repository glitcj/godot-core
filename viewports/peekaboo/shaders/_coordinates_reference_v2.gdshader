shader_type canvas_item;
render_mode blend_mix;

varying vec2 screen_position;
varying vec2 world_position;
varying vec2 ndc_position;

void vertex() {
    // --- SPACE 1: Local space (raw, untransformed) ---
    vec2 local_pos = VERTEX;

    // --- SPACE 2: World/Canvas space ---
    vec4 world = MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0);
    world_position = world.xy;

    // --- SPACE 3: Screen pixel space ---
    vec4 screen = CANVAS_MATRIX * world;
    screen_position = screen.xy;

    // --- SPACE 4: NDC / Clip space [-1..1] ---
    vec4 ndc = SCREEN_MATRIX * screen;
    ndc_position = ndc.xy;
}

void fragment() {
    // === UV SPACE [0..1] ===
    vec2 uv_a = screen_position * SCREEN_PIXEL_SIZE;
    vec2 uv_b = VERTEX * SCREEN_PIXEL_SIZE;
    vec2 uv_c = SCREEN_UV;
    vec2 uv_d = FRAGCOORD.xy * SCREEN_PIXEL_SIZE;

    // === PIXEL SPACE [0..screen_size] ===
    vec2 px_a = screen_position;
    vec2 px_b = VERTEX;
    vec2 px_c = FRAGCOORD.xy;

    // === WORLD/CANVAS SPACE ===
    vec2 world_px = world_position;

    // === NDC SPACE [-1..1] ===
    // Canvas/screen pixel coords go from [0..screen_size] — absolute pixel positions.
    // e.g. (640, 360) on a 1280x720 screen means dead center in pixels.
    // NDC remaps that to [-1..1] on both axes: (-1,-1) top-left, (0,0) center, (1,1) bottom-right.
    // Godot uses NDC internally — MODEL/CANVAS/SCREEN_MATRIX exist to get vertices into this space.
    // Useful in 2D for effects that need symmetric "distance from center" math.
    vec2 ndc = ndc_position;                  // from varying (via SCREEN_MATRIX in vertex)
    // vec2 ndc = SCREEN_UV * 2.0 - 1.0;     // equivalent, if you don't need the varying

    // === TEXTURE UV ===
    vec2 tex_uv = UV;
}
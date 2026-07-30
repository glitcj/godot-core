shader_type canvas_item; // tells Godot this runs on a 2D sprite/node

// uniforms = knobs you set from GDScript
// float = single number | vec4 = 4 numbers (r,g,b,a)
uniform float progress  : hint_range(0.0, 1.0) = 0.0;
uniform vec4  tint      : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float wave_amp  : hint_range(0.0, 0.1) = 0.03;
uniform float wave_freq : hint_range(1.0, 20.0) = 8.0;

// -------------------------------------------------------
// vertex() runs exactly 4 times — once per corner
// there are NO pixels yet at this stage
// -------------------------------------------------------
void vertex() {

    // VERTEX = the corner's (x,y) in local pixel space
    // writing to it moves that corner on screen
    // the texture does NOT follow — geometry moves, UV stays
    VERTEX.x += sin(VERTEX.y * wave_freq + TIME * 2.0) * wave_amp;

    // UV = the texture coordinate for this corner (0.0 to 1.0)
    // writing to it shifts where the texture is anchored
    // the sprite does NOT move — texture scrolls inside it
    // UV.x += TIME * 0.1; // ← would scroll texture, not move sprite

    // TIME = seconds since game start. read-only. same in both shaders
}

// -------------------------------------------------------
// rasterization happens here automatically — no code needed
// GPU fills every pixel inside the two triangles
// it interpolates the 4 corner UVs across all pixels smoothly
// example: pixel halfway across the sprite → UV.x = 0.5
// this is why changing a corner UV shifts ALL pixels inside
// FRAGCOORD is also generated here — real screen pixel position
// -------------------------------------------------------

// -------------------------------------------------------
// fragment() runs once per pixel — potentially millions of times
// -------------------------------------------------------
void fragment() {

    // UV = interpolated texture coord for THIS pixel (read-only here)
    // it is NOT affected by what you did to VERTEX
    // to displace pixels individually, make a new coord instead:
    vec2 warped = UV;                                    // copy UV — don't touch the original
    warped.x += sin(UV.y * 10.0 + TIME) * 0.05;        // unique offset per row → wave warp

    // TEXTURE is a sampler — NOT a vec4
    // it's a lookup table holding the image data
    // texture(TEXTURE, coord) = open the table at 'coord' and return a vec4
    //          ↑ sampler2D     ↑ vec2 address             ↑ returns (r,g,b,a)
    vec4 tex = texture(TEXTURE, warped);                 // read color at the warped position

    // FRAGCOORD = actual screen pixel in window coords e.g. (452.0, 318.0)
    // unlike UV, it DOES reflect any VERTEX displacement

    // UV.y is 0 at top, 1 at bottom — useful for gradients
    vec3 tinted = mix(tex.rgb, tint.rgb, tint.a * UV.y * progress);

    // COLOR = the output — whatever you write here becomes the pixel on screen
    COLOR.rgb = tinted;  // set the color
    COLOR.a   = tex.a;   // preserve original alpha so transparency still works
}
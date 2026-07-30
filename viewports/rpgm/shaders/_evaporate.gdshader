shader_type canvas_item;

// How far along the evaporation is. 0 = fully visible, 1 = fully gone.
uniform float evaporate_progress : hint_range(0.0, 1.0) = 0.5;
// The glowing outline color that appears at the dissolve boundary.
uniform vec4 edge_color : source_color = vec4(0.6, 0.9, 1.0, 1.0);
// How wide the glowing edge band is.
uniform float edge_width : hint_range(0.0, 0.3) = 0.08;
// How zoomed-in the noise is. Higher = chunkier dissolve shapes.
uniform float noise_scale : hint_range(1.0, 20.0) = 6.0;
// How fast the noise drifts upward, giving the "rising steam" feel.
uniform float rise_speed : hint_range(0.0, 5.0) = 1.2;


// ── HASH ─────────────────────────────────────────────────────────────────────
// Takes a 2D coordinate and returns a pseudo-random float in [0, 1].
// This is just math that scrambles the input — sin + big multiplier + fract
// produces numbers that look random but are 100% deterministic (same in = same out).
// No true randomness here; it's a pure function used as the seed for noise.
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


// ── SMOOTH NOISE ─────────────────────────────────────────────────────────────
// Wraps noise() to produce smooth, continuous values instead of hard random jumps.
// Raw noise() jumps sharply between grid points — smooth_noise blends neighbors
// so the result flows gradually as p moves through space.
float smooth_noise(vec2 p) {
    vec2 i = floor(p);  // Which grid cell we're in (integer corner).
    vec2 f = fract(p);  // How far inside that cell we are (0→1 in x and y).

    // This cubic curve (equivalent to smoothstep) replaces the raw linear f.
    // Without it, blending between corners would look like a flat gradient.
    // With it, values ease in/out — removing visible grid line artifacts.
    f = f * f * (3.0 - 2.0 * f);

    // Sample noise at all four corners of the current grid cell.
    float a = noise(i);                    // bottom-left
    float b = noise(i + vec2(1.0, 0.0));  // bottom-right
    float c = noise(i + vec2(0.0, 1.0));  // top-left
    float d = noise(i + vec2(1.0, 1.0));  // top-right

    // Bilinear blend across the cell using f (our smoothed position inside it).
    // mix(a, b, t) = a + (b-a)*t, so this interpolates first along x, then y.
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}


// ── FBM (Fractal Brownian Motion) ─────────────────────────────────────────────
// Stacks multiple layers ("octaves") of smooth_noise at increasing frequencies
// and decreasing amplitudes to build up natural-looking complexity.
//
// One layer of smooth_noise looks like soft blobs — too simple and uniform.
// FBM adds finer and finer detail on top, like how clouds have large shapes
// with smaller wisps layered over them.
//
// Each loop iteration:
//   - doubles the frequency (p *= 2.1) → finer detail
//   - halves the amplitude  (a *= 0.5) → quieter contribution
// So layer 0 is big slow shapes, layer 3 is tiny fast detail.
float fbm(vec2 p) {
    float v = 0.0; // Accumulated noise value.
    float a = 0.5; // Current amplitude (starts at 0.5 so total stays ≈ 0→1).
    for (int i = 0; i < 4; i++) {
        v += a * smooth_noise(p);
        p *= 2.1; // Zoom in — next layer is at higher frequency.
        a *= 0.5; // Quieter — so finer layers don't overpower the base shape.
    }
    return v;
}


// ── FRAGMENT ──────────────────────────────────────────────────────────────────
void fragment() {
    vec4 tex_color = texture(TEXTURE, UV); // Original sprite pixel at this UV.

    // Sample noise at a UV that drifts upward over time.
    // Subtracting TIME*rise_speed from the y coordinate makes the noise pattern
    // float upward each frame, giving the evaporation a rising-steam feel.
    vec2 noise_uv = UV * noise_scale + vec2(0.0, -TIME * rise_speed);
    float n = fbm(noise_uv);

    // UV.y = 0 is the top of the sprite, 1 is the bottom.
    // We want the top to vanish first, so we lower the threshold near the top.
    // bias is 0 at the bottom (UV.y=1) and 0.4 at the top (UV.y=0),
    // making upper pixels hit their dissolve threshold sooner.
    float bias = (1.0 - UV.y) * 0.4;
    float threshold = evaporate_progress - bias;

    // step(edge, x) returns 1 if n >= threshold, 0 if not.
    // So dissolve = 1 where noise is above the threshold (pixel stays),
    // and 0 where noise is below it (pixel disappears).
    float dissolve = step(threshold, n);

    // ── EDGE GLOW ──────────────────────────────────────────────────────────
    // We want a soft glowing band right at the dissolve boundary.
    float inner = threshold;              // Where the glow starts (dissolve line).
    float outer = threshold + edge_width; // Where the glow fades out completely.

    // smoothstep(a, b, x) ramps 0→1 as x goes from a to b.
    // mix(inner, outer, 0.5) is just the midpoint between inner and outer.
    //
    // First smoothstep:  ramps UP from inner → midpoint.
    // Second smoothstep: ramps DOWN from midpoint → outer (the 1.0 - flips it).
    // Multiplying them creates a triangle pulse: zero outside the band,
    // peaks at the midpoint, back to zero at outer.
    float edge = smoothstep(inner, mix(inner, outer, 0.5), n)
               * (1.0 - smoothstep(mix(inner, outer, 0.5), outer, n));

    vec4 final_color = tex_color;

    // Blend the glow color into the sprite wherever edge > 0.
    // edge_color.a controls how strongly the glow overrides the sprite color.
    final_color.rgb = mix(final_color.rgb, edge_color.rgb, edge * edge_color.a);

    // Kill alpha where dissolve = 0 (pixel has evaporated).
    // Multiplying preserves the sprite's own transparency everywhere else.
    final_color.a = tex_color.a * dissolve;

    COLOR = final_color;
}

// ── WHY PROCEDURAL NOISE INSTEAD OF A NOISE TEXTURE SAMPLER? ─────────────────
//
// There are two ways to get noise in a shader:
//
// 1. PROCEDURAL (what this shader does)
//    Noise is computed purely in math each frame — no texture asset needed.
//    The hash() → smooth_noise() → fbm() chain runs for every pixel every frame.
//    Upside:  zero setup, no Inspector assignment, no imported asset.
//    Downside: more GPU math per pixel than a texture lookup.
//
// 2. NOISE TEXTURE SAMPLER
//    Noise is pre-baked into a texture, then sampled with a cheap texture()
//    lookup. GPUs are massively optimized for texture reads so this is fast.
//    Upside:  very cheap at runtime.
//    Downside: requires a noise texture asset created and assigned in the
//              Inspector. It's also static — animating it means either scrolling
//              the UV on the CPU side, or doing multiple texture samples at
//              different scales to replicate FBM layering (which gets messy).
//
// FOR THIS EFFECT, PROCEDURAL IS THE BETTER CHOICE because:
//   - The noise UV is offset by TIME every frame to make it drift upward.
//     A texture could scroll the same way, but replicating the 4-octave FBM
//     detail would require 4 separate texture samples at different scales.
//   - A dissolve shader runs on a sprite — relatively few pixels — so the
//     extra math cost is negligible in practice.
//
// GENERAL RULE OF THUMB:
//   Procedural → animated, layered, no assets needed, slightly higher GPU cost.
//   Noise texture → static or simply scrolled, very cheap, requires an asset.
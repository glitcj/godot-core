# Godot Canvas Item Shader: VERTEX, varying, and COLOR explained

## Updated Table

| | `VERTEX` | `varying_vertex` | `COLOR` |
|---|---|---|---|
| **In `vertex()`** | Local object-space position (read/write) | You write to it here | The node's **modulate color** coming in (read/write) |
| **In `fragment()`** | Screen-space pixel position (read-only) | Interpolated local position (read-only) | The **output** — you write the final pixel color here |
| **Range (48px sprite)** | Screen coords e.g. `(640, 360)` | Interpolated from `(-24,-24)` to `(24,24)` | `vec4` you assign to paint the pixel |
| **As RGB color** | Clamps to solid yellow | Gradient across the quad | Whatever you set — this is the actual drawn result |

`COLOR` is essentially directional — in `vertex()` it's data flowing *in* (the node's tint/modulate), in `fragment()` it's data flowing *out* (the pixel you're painting).

---

## Why each fragment sees a different varying value

Your mental model is right that vertex runs first, then fragment — but there's a **third stage between them** that the GPU handles automatically: **rasterization + interpolation**.

```
vertex() runs        Rasterizer              fragment() runs
on each corner  →   fills in the quad   →   on each pixel
                    and interpolates
                    varyings for each
                    covered pixel
```

For your sprite quad, `vertex()` runs exactly **4 times** (once per corner), producing 4 `varying_vertex` values:

```
(-24,-24) ──────── (24,-24)
    |                  |
    |    rasterizer     |
    |    fills this     |
    |    entire area    |
    |                  |
(-24, 24) ──────── (24, 24)
```

The rasterizer then asks *"what pixel coordinates does this quad cover?"* — say 48×48 = 2304 pixels — and for **each one** it computes a weighted blend of the 4 corner values using **barycentric coordinates** (essentially: how close is this pixel to each corner?).

```
Pixel at dead center → varying_vertex = (0, 0)
Pixel at top-right   → varying_vertex ≈ (24, -24)
Pixel at 75% right, 25% down → varying_vertex ≈ (12, -12)
```

You never write this interpolation code — the GPU does it automatically for anything you mark `varying`. That's literally the entire job of the `varying` keyword: *"GPU, please interpolate this between my vertex outputs and hand each fragment its share."*

So `fragment()` doesn't "see a vertex" at all — it sees a **GPU-computed blend** of the surrounding vertices, calculated before `fragment()` even starts.

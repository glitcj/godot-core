shader_type canvas_item;
render_mode light_only;


void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    // Set RGB to 0 so we don't "double add" the brightness.
    // We KEEP the alpha so the light knows where the pixels are.
    COLOR = vec4(0.0, 0.0, 0.0, tex.a);
}

void light() {
    // We need to pull the texture again here since COLOR is now black.
    vec4 tex = texture(TEXTURE, UV);
    
    // This will now be: 0 (from fragment) + (Texture * Light)
    // This results in the exact texture colors.
    vec3 final_rgb = tex.rgb * LIGHT_COLOR.rgb;
    
    // Use the light's alpha to handle your "white to transparent" gradient.
    float final_a = tex.a * LIGHT_COLOR.a;

    LIGHT = vec4(final_rgb, final_a);
}

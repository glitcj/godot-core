shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// We can still keep intensity as a "multiplier" for the pulse
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;


void fragment() {
    // Add this if you are using an AtlasTexture / SpriteSheet
    // It ensures UVs are relative to the current frame, not the whole sheet
    // Note: In Godot 4, this is often handled, but check your texture settings.
	
    vec4 tex_color = texture(TEXTURE, UV);
    
    // sin(TIME) goes from -1.0 to 1.0. 
    // We use abs() or (sin+1)/2 to keep it in the 0.0 to 1.0 range.
    float time_factor = (sin(TIME * pulse_speed) + 1.0) / 2.0;
    
    // Mix using our new time_factor instead of a static slider
    vec4 final_color = mix(tex_color, flash_color, time_factor);
    
    final_color.a *= tex_color.a;
    COLOR = final_color;
}
shader_type canvas_item;

uniform float x_speed : hint_range(0.0, 10.0) = 2.;
uniform float y_speed : hint_range(0.0, 10.0) = 0.;

void vertex() {
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec4 pixel = texture(TEXTURE, UV + vec2(fract(TIME * x_speed / 10.), fract(TIME * y_speed / 10.)));
    COLOR = pixel;
}
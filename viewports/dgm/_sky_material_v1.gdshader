shader_type sky;

uniform sampler2D panorama_sampler : filter_linear, source_color, hint_default_black;

uniform float speed = .005;

void vertex() {
	// Called for every vertex the material is visible on.
}

void sky() {
	vec2 xy = SKY_COORDS + vec2(TIME * speed + sin(TIME) / 1000., 0.);
	// vec3 modulator = vec3(sin(xy.x)) * 1.2;
	//float modulator = SKY_COORDS.x;
	float modulator = SKY_COORDS.y;
	

	vec3 texel = texture(panorama_sampler, xy).rgb ;
	texel.r = mix(0., texel.r, sin(xy.x * TIME)*1.1);
	texel = vec3(modulator) ;
	
	COLOR.rgb = texel;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

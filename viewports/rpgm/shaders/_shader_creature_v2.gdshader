shader_type canvas_item;
render_mode blend_mix;
uniform float progress   : hint_range(0.0, 1.0)   = 0.0;
uniform vec4  tint       : source_color            = vec4(1.0, 0.5, 1.0, 1.0);
uniform float wave_amp   : hint_range(0.0, 0.1)   = 0.03;
uniform float wave_freq  : hint_range(1.0, 20.0)  = 8.0;
uniform float wave_phase : hint_range(0.0, 100.0) = 10.0;
uniform float frame_size : hint_range(0.0, 1028.0) = 48.0;
uniform bool run_vertex;
uniform bool run_fragment; // uniform bools are safe to branch on — same value for every fragment, whole warp takes the same path, no divergence
uniform sampler2D noise_tex;
uniform float noise_scale  : hint_range(0.1, 5.0) = 1.0;
uniform float noise_speed  : hint_range(0.0, 2.0) = 0.025;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.4;
uniform bool time_as_progress = true ;
// uniform float speed: hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float angle : hint_range(0.0, 3.14 * 2., 0.0) = 0.0 ;


vec4 black_as_transparent(vec4 _pixel) {
	// vec4 value = _pixel ;
	// value.a = mix(0., 1.,  step(0.1, distance(_pixel.rgb, vec3(0.,0.,0.))) ) ;
	// _pixel.a = length(_pixel.rgb) ;
	_pixel.a = length(_pixel.rgb) ;
	return _pixel ;
	//return value ;
	
}

vec4 _circle(vec2 _centered_uv) {
	vec4 filled_circle = vec4(1.) ;
	
	filled_circle.rgb = vec3(distance(_centered_uv, vec2(0., 0.))) ;
	
	filled_circle.rgb = vec3(1.) - filled_circle.rgb ;
	filled_circle = max(vec4(0.), filled_circle) ; // clamp negative values
	
	filled_circle = black_as_transparent(filled_circle) ;
	return filled_circle ;
	
} 


vec4 _harden(vec4 _pixel) { // }, float edge) {
	// apply hard edge
	vec4 _hardened_pixel = step(0.000001, _pixel) ;
	// return  mix(vec4(0.), _pixel, _hardened_pixel) ;
	return  mix(vec4(0.), vec4(1.), _hardened_pixel) ;
	}

vec4 _soften(vec4 _pixel) {
	return vec4(1.) ;
}

vec2 _center(vec2 _uv) {
	return _uv ;
	}

vec2 _rotate(vec2 _uv, float _angle) {
	mat3 rotation = mat3(vec3(cos(_angle), -sin(_angle), 0.), vec3(sin(_angle), cos(_angle), 0.), vec3(0., 0., 1.));
	return (rotation * vec3(_uv, 1.)).xy   ;

}
vec2 _translate(vec2 _uv, vec2 offset) {
	mat3 translation = mat3( 
		vec3(1., 0., 0.), 
		vec3(0., 1., 0.), 
		vec3(offset.x, offset.y, 1.)
		) ;
	return (translation * vec3(_uv, 1.)).xy ;
}

vec2 _scale(vec2 _uv, float scale) {
	mat3 scaler = mat3( 
		vec3(1./scale, 0., 0.), 
		vec3(0., 1./scale, 0.), 
		vec3(0., 0., 1.)
		) ;
	return (scaler * vec3(_uv, 1.)).xy ;
}

vec2 _scroll(vec2 _uv) {
	return vec2(1.) ;
}

vec4 _ellipse(vec2 _centered_uv, vec2 radius) {	
	
	
	// draw ellipse
	vec4 filled_ellipse = vec4(1.) ;
	filled_ellipse.rgb = vec3(length((_centered_uv - vec2(0., 0.)) / radius )) ;
	filled_ellipse.rgb = vec3(1.) - filled_ellipse.rgb ;
	filled_ellipse.rgb = max(vec3(0.), filled_ellipse.rgb) ; // clamp negative values from ellipse equation
	

	// remove background
	filled_ellipse = black_as_transparent(filled_ellipse) ;	
	
	return filled_ellipse;
	
} 


vec4 _stack() {return vec4(0.) ;}

void vertex() {}
void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec4 pixel = vec4(0.) ;
	vec4 noxel ;
	vec2 centered_uv = UV * 2. - 1. ;
	vec2 cartesian_uv = vec2(centered_uv.x, -centered_uv.y ) ;
	
	// Using ifs on uniform variables is GPU friendly, because all pixels will follow exactly the same instruction path.
	// if (!run_fragment) { 
	if (true) { 
		
		
		vec4 noxel_octave_1 = texture(noise_tex, vec2( fract(UV.x + TIME / (1./noise_speed)) , UV.y));
		vec4 noxel_octave_2 = texture(noise_tex, vec2( fract(UV.x + TIME / (1./noise_speed)) , fract(UV.y + .5) ));
		noxel = noxel_octave_1 ;
		
		
		vec2 _body_1_swing = vec2(0.0, 0.015) * sin(TIME) ; 
		vec2 _light_1_swing = vec2(0.0, 0.0)  * sin(TIME) ;
		vec2 _eye_1_swing = vec2(0.0, 0.2)  * sin(TIME * 1.02) ;
		
		
		vec2 _body_1_uv = _scale(_translate(_rotate(centered_uv, angle), vec2(0., 0.) + _body_1_swing), .2) ;
		vec2 _light_1_uv = _translate(_scale(_rotate(centered_uv, angle) , .4), vec2(0.5, 0.0) + _light_1_swing) ;
		vec2 _ellipse_uv =  _scale(_translate(_rotate(centered_uv, angle + PI/8.), vec2(0., 0.)), .5 + sin(TIME/1.5)/13.) ;
		
		
		vec2 _eye_1_uv = _translate(_scale(_rotate(centered_uv, angle) , .03), vec2(4., 0.0) + _eye_1_swing) ;
		vec4 eye_1 = _harden(_circle(_eye_1_uv)) ;
		
		vec2 _eye_2_uv = _translate(_scale(_rotate(centered_uv, angle) , .03), vec2(-1.5, 0.0) + _eye_1_swing) ;
		vec4 eye_2 = _harden(_circle(_eye_2_uv)) ;

		vec2 _eye_3_uv = _translate(_scale(_rotate(centered_uv, angle) , .03), vec2(1.4, 3.0) + _eye_1_swing) ;
		vec4 eye_3 = _harden(_circle(_eye_3_uv)) ;
		
		
		vec4 _body_1 = _harden(_circle(_body_1_uv)) ;
		vec4 circle_2 = _circle(_light_1_uv) ;
		vec4 circle_3 = mix(circle_2, _body_1, 1. - _body_1) ;
		vec4 ellipse_1 = _ellipse(_ellipse_uv, vec2(1., 2.)) ;
		
		ellipse_1 =  mix(vec4(0.), ellipse_1, length(noxel.rgb)) ;
		
		
		
		
		// stack
		pixel = mix(ellipse_1, circle_3, _body_1.a) ;
		pixel = mix(pixel, eye_1, eye_1.a) ;
		pixel = mix(pixel, eye_2, eye_2.a) ;
		pixel = mix(pixel, eye_3, eye_3.a) ;
		// pixel = noxel ;

	}
	COLOR = pixel ;
}
shader_type spatial;


uniform sampler2D _texture;
uniform sampler2D _L_texture;
uniform float light=1.0;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ROUGHNESS=0.0;
	METALLIC=0.97;
	vec4 color=texture(_texture,UV);
	vec4 l_color=texture(_L_texture,UV);
	ALBEDO.rgb=color.rgb;
	EMISSION=vec3(0.4,0.2,0.8)*0.01*light+l_color.rgb*(light+0.2);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

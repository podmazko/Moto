shader_type spatial;


uniform sampler2D _texture;
uniform float light=1.0;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 color=texture(_texture,UV);
	ALBEDO.rgb=color.rgb*color.rgb*0.6;
	EMISSION=vec3(0.4,0.2,0.8)*0.03*light;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

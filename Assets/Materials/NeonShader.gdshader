shader_type spatial;
render_mode unshaded;

uniform float light=1.0;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO.rgb=vec3(0.4,0.2,0.8)*(0.5*light+0.1);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

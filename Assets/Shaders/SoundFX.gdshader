shader_type canvas_item;



uniform float light=1.0;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR.rgb=vec3(0.5,0.2,1.2)*light;
	COLOR.a=0.3*light;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

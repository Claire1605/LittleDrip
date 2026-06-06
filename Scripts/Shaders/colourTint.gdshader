shader_type canvas_item;
uniform vec4 colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);
//uniform float tint_Factor : hint_range(0.0, 1.0) = 0.5;
//uniform float fade : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 main_texture = texture(TEXTURE, UV);
	vec4 final_output = main_texture;
	
	//float original_modulation = 1.0 - tint_Factor;
	//final_output.rgb = mix(main_texture.rgb * original_modulation, colour.rgb * tint_Factor, tint_Factor);
	final_output.rgb = colour.rgb * main_texture.rgb;
	//final_output.a *= fade;
	
	COLOR = final_output;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

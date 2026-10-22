shader_type canvas_item;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.96, 0.80, 1.0);
void fragment() {
	vec4 pixel = COLOR;
	// Preserve dark outlines so a hit does not inflate the silhouette.
	float interior = step(0.25, max(pixel.r, max(pixel.g, pixel.b)));
	COLOR = vec4(mix(pixel.rgb, flash_color.rgb, flash_amount * interior), pixel.a);
}

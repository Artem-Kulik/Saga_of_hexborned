shader_type canvas_item;

uniform sampler2D mask_texture;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 mask = texture(mask_texture, UV);

	// беремо яскравість маски
	float alpha = mask.r;
COLOR = vec4(tex.rgb, tex.a * alpha);
}
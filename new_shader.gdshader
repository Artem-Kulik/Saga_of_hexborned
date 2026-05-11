shader_type canvas_item;

uniform sampler2D mask_texture;

void fragment() {
    vec4 portrait = texture(TEXTURE, UV);
    vec4 mask = texture(mask_texture, UV);

    portrait.a *= mask.r;

    COLOR = portrait;
}

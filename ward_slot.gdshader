shader_type canvas_item;

uniform sampler2D mask_texture;
uniform vec4 highlight_color : source_color = vec4(1.0, 0.7, 0.2, 0.5);

void fragment() {
    vec4 mask = texture(mask_texture, UV);

    COLOR = vec4(highlight_color.rgb, mask.r * highlight_color.a);
}

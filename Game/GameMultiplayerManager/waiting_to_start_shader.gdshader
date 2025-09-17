shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_amount = 1.0;

void fragment() {
    COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
}

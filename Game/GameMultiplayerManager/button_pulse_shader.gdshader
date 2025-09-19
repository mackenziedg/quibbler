shader_type canvas_item;

uniform vec2 size = vec2(198.0, 112.0);
uniform float pulse_scale = 10.0;
uniform float pulse_speed = 2.0;

void vertex() {
    float scale = (pulse_scale - 1.0) * (sin(TIME * pulse_speed) + 1.0) * 0.5;
    VERTEX += (VERTEX - size * 0.5) * scale;
}


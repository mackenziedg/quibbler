shader_type canvas_item;

void vertex() {
    VERTEX.y += 2.0 * sin(TIME + VERTEX.x * 50.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
}

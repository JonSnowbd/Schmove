shader_type canvas_item;

uniform float progress;
uniform vec4 blackout;

void fragment() {
	vec4 next = vec4(0.0f);
	vec4 prev = texture(TEXTURE, UV);
	float p = clamp(progress, 0.002f, 1.0f);
	
	float p1 = clamp(p/0.5f, 0.0f, 1.0f);
	float p2 = clamp((p*2.0f)-1.0f, 0.0f, 1.0f);
	
	float radPos = distance(UV, vec2(0.5,0.5));
	
	if(p < 0.5f) {
		if(radPos == 0.0f || radPos < p1) {
			COLOR = blackout;
		} else {
			COLOR = prev;
		}
	} else {
		if(radPos == 0.0f || radPos < (p2)) {
			COLOR = next;
		} else {
			COLOR = blackout;
		}
	}
}

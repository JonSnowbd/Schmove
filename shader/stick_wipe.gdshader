shader_type canvas_item;

uniform float progress;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec4 next = vec4(0.0f);
	vec4 prev = texture(TEXTURE, UV);
	float p = clamp(progress, 0.002f, 1.0f);

	vec2 newUV = UV;
	newUV.x += (p * ((random(vec2(0.0f, UV.y)) * 2.0f)-1.0f))*0.4f;
	vec4 current = mix(texture(TEXTURE,newUV), next, p);
	COLOR = current;
}
varying vec2 uv;

uniform sampler2D texture;

const float levels = 8.0;

void main() {
	vec3 rgb = texture2D(texture, uv).rgb;
	vec3 quantizedRGB = (1.0 / levels) * floor(levels * rgb);
    gl_FragColor = vec4(quantizedRGB, 1.0);
}

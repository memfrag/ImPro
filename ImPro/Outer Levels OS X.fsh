varying vec2 uv;

uniform sampler2D texture;

const float lower = 0.4;
const float upper = 0.8;

void main() {
    vec3 rgb = texture2D(texture, uv).rgb;
	vec3 color = (1.0 / (upper - lower)) * (-lower + clamp(rgb, lower, upper));
	gl_FragColor = vec4(color, 1.0);
}

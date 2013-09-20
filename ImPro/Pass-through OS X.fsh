varying vec2 uv;

uniform sampler2D texture;

void main() {
    vec3 rgb = texture2D(texture, uv).rgb;
	gl_FragColor = vec4(rgb, 1.0);
}

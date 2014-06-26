varying vec2 uv;

uniform sampler2D texture;
const float exposure = 0.4;

void main() {
    vec3 rgb = texture2D(texture, uv).rgb;
	rgb *= pow(2.0, exposure);
    gl_FragColor = vec4(rgb, 1.0);
}

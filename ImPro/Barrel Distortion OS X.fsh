varying vec2 uv;

uniform sampler2D texture;

const float PI = 3.141592535;
const float barrelPower = 0.7;

vec2 distort(vec2 p) {
	float theta = atan(p.y, p.x);
	float radius = length(p);
	radius = pow(radius, barrelPower);
	p.x = radius * cos(theta);
	p.y = radius * sin(theta);
	return 0.5 * (p + 1.0);
}

void main() {
	vec2 xy = 2.0 * uv - 1.0;
	vec2 uv2 = uv;
	float d = length(xy);
	if (d < 1.0) {
		uv2 = distort(xy);
	}
    vec3 rgb = texture2D(texture, uv2).rgb;
	gl_FragColor = vec4(rgb, 1.0);
}

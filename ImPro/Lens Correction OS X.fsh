varying vec2 uv;

uniform sampler2D texture;

const float strength = 1.05;

void main() {
    float correctionRadius = 1.414213562373 / strength;
    
	vec2 xy = 2.0 * uv - 1.0;
	float d = length(xy);
    float r = d / correctionRadius;
	
    float theta = 1.0;
    if (r > 0.0) {
        theta = atan(r) / r;
    }
    
    vec2 uv2 = vec2(0.5 * (theta * xy + 1.0));
    
    vec3 rgb = texture2D(texture, uv2).rgb;
	gl_FragColor = vec4(rgb, 1.0);
}

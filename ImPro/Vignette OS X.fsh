varying vec2 uv;

uniform sampler2D texture;

const vec2 vignetteCenter = vec2(0.5, 0.5);
const vec3 vignetteColor = vec3(0.0, 0.0, 0.0);
const float vignetteStart = 0.3;
const float vignetteEnd = 0.7;

void main()
{
    vec3 rgb = texture2D(texture, uv).rgb;
    float d = distance(uv, vec2(vignetteCenter.x, vignetteCenter.y));
    float percent = smoothstep(vignetteStart, vignetteEnd, d);
    gl_FragColor = vec4(mix(rgb, vignetteColor, percent), 1.0);
}

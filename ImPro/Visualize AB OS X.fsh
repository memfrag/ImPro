varying vec2 uv;

uniform sampler2D texture;

// Matrix for transforming RGB to XYZ. Matrix in column major order.
const mat3 rgbToXYZTransformMatrix = mat3(0.41242400, 0.21265600, 0.01933240,
                                          0.35757900, 0.71515800, 0.11919300,
                                          0.18046400, 0.07218560, 0.95044400);

const mat3 xyzToRGBTransformMatrix = mat3(3.24070846, -0.96925735, 0.05563507,
                                          -1.53725917, 1.87599516, -0.20399580,
                                          -0.49857039, 0.04155555, 1.05706957);

const vec3 ref = vec3(95.047, 100.000, 108.883);
const vec3 oneOverRef = vec3(1.0 / 95.047, 1.0 / 100.000, 1.0 / 108.883);
const vec3 oneThird = vec3(1.0 / 3.0);
const vec3 oneOverTwoPointFour = vec3(1.0 / 2.4);
const vec3 twoPointFour = vec3(2.4);

vec3 rgbToXYZ(const vec3 rgbColor) {
    
    // Using the step function to avoid an if, since ifs are terribly
    // expensive in shaders. The pow is going to be somewhat expensive
    // too, but it's hopefully the lesser of two evils. :-)
    vec3 k = step(0.04045, rgbColor);
    vec3 c = (1.0 - k) * (rgbColor * (1.0 / 12.92))
    + k * (pow(((rgbColor + 0.055) / 1.055), twoPointFour));
    
    c = c * 100.0;
    
    vec3 xyz = rgbToXYZTransformMatrix * c;
    return xyz;
}

vec3 xyzToRGB(const vec3 xyzColor) {
    vec3 color = xyzColor * (1.0 / 100.0);
    
    vec3 r = xyzToRGBTransformMatrix * color;
    
    vec3 k = step(0.0031308, r);
    vec3 rgb = (1.0 - k) * (12.92 * r) + k * (1.055 * pow(r, oneOverTwoPointFour) - 0.055);
    
    return rgb;
}

vec3 xyzToLab(const vec3 xyzColor) {
    vec3 r = xyzColor * oneOverRef;
    
    vec3 k = step(vec3(0.008856), r);
    vec3 c = (1.0 - k) * ((7.787 * r) + (16.0 / 116.0))
    + k * pow(r, oneThird);
    
    vec3 lab = vec3(116.0 * c.y - 16.0,
                    500.0 * (c.x - c.y),
                    200.0 * (c.y - c.z));
    return lab;
}

vec3 labToXYZ(const vec3 labColor) {
    float y = (labColor.x + 16.0) / 116.0;
    vec3 r = vec3(y + labColor.y / 500.0, y, y - labColor.z / 200.0);
    vec3 r3 = r * r * r;
    
    vec3 k = step(vec3(0.008856), r3);
    vec3 c = (1.0 - k) * ((r - (16.0 / 116.0)) / 7.787)
    + k * r3;
    
    vec3 xyz = c * ref;
    return xyz;
}

void main() {
    vec4 rgb = texture2D(texture, uv);
    vec3 xyz = rgbToXYZ(rgb.rgb);
    vec3 lab = xyzToLab(xyz);
    
    float a = (lab.g + 128.0) / 256.0;
    float b = (lab.b + 128.0) / 256.0;
    
    gl_FragColor = vec4(a, 0.0, b, 1.0);
}

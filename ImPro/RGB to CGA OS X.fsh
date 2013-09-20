varying vec2 uv;

uniform sampler2D texture;

void main()
{
    vec2 sampleDivisor = vec2(1.0 / 400.0, 1.0 / 640.0);
    //highp vec4 colorDivisor = vec4(colorDepth);
    
    vec2 samplePos = uv - mod(uv, sampleDivisor);
    vec4 color = texture2D(texture, samplePos );
    
    //gl_FragColor = texture2D(inputImageTexture, samplePos );
    vec4 colorCyan = vec4(85.0 / 255.0, 1.0, 1.0, 1.0);
    vec4 colorMagenta = vec4(1.0, 85.0 / 255.0, 1.0, 1.0);
    vec4 colorWhite = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 colorBlack = vec4(0.0, 0.0, 0.0, 1.0);
    
    vec4 endColor;
    float blackDistance = distance(color, colorBlack);
    float whiteDistance = distance(color, colorWhite);
    float magentaDistance = distance(color, colorMagenta);
    float cyanDistance = distance(color, colorCyan);
    
    vec4 finalColor;
    
    float colorDistance = min(magentaDistance, cyanDistance);
    colorDistance = min(colorDistance, whiteDistance);
    colorDistance = min(colorDistance, blackDistance);
    
    if (colorDistance == blackDistance) {
        finalColor = colorBlack;
    } else if (colorDistance == whiteDistance) {
        finalColor = colorWhite;
    } else if (colorDistance == cyanDistance) {
        finalColor = colorCyan;
    } else {
        finalColor = colorMagenta;
    }
    
    gl_FragColor = finalColor;
}

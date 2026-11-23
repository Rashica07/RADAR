#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

/// Cover "film": soft-light grain plus faint scanlines, computed per pixel on the GPU.
/// - pitch: distance between scanlines in points
/// - scan:  how much each scanline darkens (0…1)
/// - grain: strength of the noise overlay (0…1)
[[ stitchable ]] half4 radarFilm(float2 position, half4 color, float pitch, float scan, float grain) {
    if (color.a < 0.001h) return color;
    half3 rgb = color.rgb / color.a;

    half n = half(hash21(floor(position * 2.0)));
    half3 multiply = 2.0h * rgb * n;
    half3 screen = 1.0h - 2.0h * (1.0h - rgb) * (1.0h - n);
    half3 overlay = select(screen, multiply, rgb < 0.5h);
    rgb = mix(rgb, overlay, half(grain));

    if (fmod(floor(position.y), pitch) < 0.5) rgb *= half(1.0 - scan);
    return half4(rgb * color.a, color.a);
}

#include <metal_stdlib>
using namespace metal;

struct VertexIn  { float2 position; float4 color; };
struct VertexOut { float4 position [[position]]; float4 color; };

vertex VertexOut vertexShader(uint vid [[vertex_id]],
                              constant VertexIn *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = float4(vertices[vid].position, 0.0, 1.0);
    out.color = vertices[vid].color;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}

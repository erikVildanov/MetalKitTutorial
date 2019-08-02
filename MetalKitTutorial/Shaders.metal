//
//  Shaders.metal
//  MetalKitTutorial
//
//  Created by Erik Vildanov on 02/08/2019.
//  Copyright © 2019 Erik Vildanov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float4 color;
};

vertex Vertex vertex_func(constant Vertex *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
    return vertices[vid];
}

fragment float4 fragment_func(Vertex vert [[stage_in]]) {
    return vert.color;
}

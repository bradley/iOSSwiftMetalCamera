//
//  Test.metal
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 1/1/15.
//  Copyright (c) 2015 Bradley Griffith. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
	float4 position [[position]];
	float4 color;
	float2 textureCoordinate;
};

/* Fragment Shaders
	------------------------------------------*/

fragment float4 test_fragment(VertexOut interpolated [[stage_in]],
											  texture2d<float>  tex2D     [[ texture(0) ]],
											  sampler           sampler2D [[ sampler(0) ]])
{
	float2 offset = 0.5 * float2(cos(0.0), sin(0.0));
	float4 cr = tex2D.sample(sampler2D, interpolated.textureCoordinate + offset);
	float4 cga = tex2D.sample(sampler2D, interpolated.textureCoordinate);
	float4 cb = tex2D.sample(sampler2D, interpolated.textureCoordinate - offset);
	return float4(cr.r, cga.g, cb.b, cga.a);
}

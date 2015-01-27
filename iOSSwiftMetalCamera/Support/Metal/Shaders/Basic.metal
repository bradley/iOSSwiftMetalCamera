//
//  Shaders.metal
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 11/27/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
	packed_float3 position;
	packed_float4 color;
	packed_float2 textureCoordinate;
};

struct VertexOut {
	float4 position [[position]];
	float4 color;
	float2 textureCoordinate;
};


/* Vertex Shaders
	------------------------------------------*/

vertex VertexOut basic_vertex(const device VertexIn *vertex_array [[ buffer(0) ]],
										unsigned     int      vid           [[ vertex_id ]])
{
	VertexOut out;
	out.position = float4(vertex_array[vid].position * float3(-1.0, 1.0, 1.0), 1.0);
	out.color = vertex_array[vid].color;
	out.textureCoordinate = vertex_array[vid].textureCoordinate;
	
	return out;
}
//
//  Composite.metal
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 1/1/15.
//  Copyright (c) 2015 Bradley Griffith. All rights reserved.
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

struct Uniforms {
	float4x4 modelMatrix;
	float4x4 projectionMatrix;
};

/* Vertex Shaders
	------------------------------------------*/

vertex VertexOut composite_vertex(const device VertexIn *vertex_array [[ buffer(0) ]],
											 const device Uniforms &uniforms     [[ buffer(1) ]],
											 unsigned     int      vid           [[ vertex_id ]])
{
	
	float4x4 mv_Matrix = uniforms.modelMatrix;
	float4x4 proj_Matrix = uniforms.projectionMatrix;
	
	float4 fragmentPos4 = mv_Matrix * float4(vertex_array[vid].position * float3(-1.0, 1.0, 1.0), 1.0);
	
	VertexOut out;
	out.position = proj_Matrix * fragmentPos4;
	//out.position = float4(vertex_array[vid].position * float3(-1.0, 1.0, 1.0), 1.0);
	out.color = vertex_array[vid].color;
	out.textureCoordinate = vertex_array[vid].textureCoordinate;
	
	return out;
	
//	VertexOut out;
//	out.position = float4(vertex_array[vid].position * float3(-1.0, 1.0, 1.0), 1.0);
//	out.color = vertex_array[vid].color;
//	out.textureCoordinate = vertex_array[vid].textureCoordinate;
//	
//	return out;
}


/* Fragment Shaders
	------------------------------------------*/

fragment float4 composite_fragment(VertexOut        interpolated [[ stage_in ]],
											  texture2d<float> tex2D        [[ texture(0) ]],
											  sampler          sampler2D    [[ sampler(0) ]])
{
	return tex2D.sample(sampler2D, interpolated.textureCoordinate);
}

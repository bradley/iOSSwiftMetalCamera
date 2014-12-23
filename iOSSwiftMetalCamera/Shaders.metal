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

struct Uniforms {
	float4x4 modelMatrix;
	float4x4 projectionMatrix;
};

struct ShaderToggle {
	bool showShader;
};


/* Vertex Shaders
	------------------------------------------*/

vertex VertexOut basic_vertex(
										const device VertexIn*  vertex_array [[ buffer(0) ]],
										const device Uniforms&  uniforms     [[ buffer(1) ]],
										unsigned int vid [[ vertex_id ]])
{
	
	float4x4 mv_Matrix = uniforms.modelMatrix;
	float4x4 proj_Matrix = uniforms.projectionMatrix;
	
	float4 fragmentPos4 = mv_Matrix * float4(vertex_array[vid].position, 1.0);
	
	VertexOut out;
	out.position = proj_Matrix * fragmentPos4;
	out.color = vertex_array[vid].color;
	out.textureCoordinate = vertex_array[vid].textureCoordinate;
	
	return out;
}


/* Fragment Shaders
	------------------------------------------*/

fragment float4 basic_fragment(VertexOut interpolated [[stage_in]],
										 const device ShaderToggle*  shaderToggle [[ buffer(0) ]],
										 texture2d<float>  tex2D     [[ texture(0) ]],
										 sampler           sampler2D [[ sampler(0) ]])
{
	bool showShader = shaderToggle[0].showShader;
	if (showShader) {
		float2 offset = 0.5 * float2(cos(0.0), sin(0.0));
		float4 cr = tex2D.sample(sampler2D, interpolated.textureCoordinate + offset);
		float4 cga = tex2D.sample(sampler2D, interpolated.textureCoordinate);
		float4 cb = tex2D.sample(sampler2D, interpolated.textureCoordinate - offset);
		return float4(cr.r, cga.g, cb.b, cga.a);
	}
	else {
		return tex2D.sample(sampler2D, interpolated.textureCoordinate);
	}
}
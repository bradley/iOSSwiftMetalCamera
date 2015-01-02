//
//  HorizontalGuassian.metal
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 12/31/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//struct VertexIn {
//	packed_float3 position;
//	packed_float4 color;
//	packed_float2 textureCoordinate;
//};

struct VertexOut {
	float4 position [[position]];
	float4 color;
	float2 textureCoordinate;
};

struct Uniforms {
	float4x4 modelMatrix;
	float4x4 projectionMatrix;
};

///* Vertex Shaders
//	------------------------------------------*/
//
//vertex VertexOut horizontal_guassian_vertex(
//														const device VertexIn*  vertex_array [[ buffer(0) ]],
//														const device Uniforms&  uniforms     [[ buffer(1) ]],
//														unsigned int vid [[ vertex_id ]])
//{
//	
//	float4x4 mv_Matrix = uniforms.modelMatrix;
//	float4x4 proj_Matrix = uniforms.projectionMatrix;
//	
//	float4 fragmentPos4 = mv_Matrix * float4(vertex_array[vid].position, 1.0);
//	
//	VertexOut out;
//	out.position = proj_Matrix * fragmentPos4;
//	out.color = vertex_array[vid].color;
//	out.textureCoordinate = vertex_array[vid].textureCoordinate;
//	
//	return out;
//}


/* Fragment Shaders
	------------------------------------------*/


kernel void horizontal_guassian(texture2d<float,access::read> inputTex [[ texture(0) ]],
									texture2d<float,access::write> outputTex [[ texture(1) ]],
									uint2 gid [[ thread_position_in_grid ]])
{
	float4 inColor = inputTex.read(gid);
	outputTex.write(inColor, gid);
}
//
//fragment float4 horizontal_guassian_fragment(VertexOut interpolated [[stage_in]],
//														 texture2d<float>  tex2D     [[ texture(0) ]],
//														 sampler           sampler2D [[ sampler(0) ]])
//{
//	
//	/*
//	float4 sum = float4(0.0);
// 
//	// blur in y (vertical)
//	// take nine samples, with the distance blurSize between them
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x - 4.0 * (1/512), interpolated.textureCoordinate.y)) * 0.05;
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x - 3.0 * (1/512), interpolated.textureCoordinate.y)) * 0.09;
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x - 2.0 * (1/512), interpolated.textureCoordinate.y)) * 0.12;
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x - (1/512), interpolated.textureCoordinate.y)) * 0.15;
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x, interpolated.textureCoordinate.y)) * 0.16;
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x + (1/512), interpolated.textureCoordinate.y)) * 0.15;
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x + 2.0 * (1/512), interpolated.textureCoordinate.y)) * 0.12;
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x + 3.0 * (1/512), interpolated.textureCoordinate.y)) * 0.09;
//	sum += tex2D.sample(sampler2D,  float2(interpolated.textureCoordinate.x + 4.0 * (1/512), interpolated.textureCoordinate.y)) * 0.05;
//	
//	return sum;*/
//	
//	float q = 266;
//	
//	float blurSizeX = 1.0 / (q);
//	float blurSizeY = 1.0 / (q);
//	
//	float4 sum = float4(0.0);
//	
//	float2 pointInTexture = interpolated.textureCoordinate;
//	
//	
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 3.0*blurSizeX, pointInTexture.y - 3.0*blurSizeY)) * 1/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 2.0*blurSizeX, pointInTexture.y - 3.0*blurSizeY)) * 1/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 1.0*blurSizeX, pointInTexture.y - 3.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 0.0*blurSizeX, pointInTexture.y - 3.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 1.0*blurSizeX, pointInTexture.y - 3.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 2.0*blurSizeX, pointInTexture.y - 3.0*blurSizeY)) * 1/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 3.0*blurSizeX, pointInTexture.y - 3.0*blurSizeY)) * 1/170;
//	
//	
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 3.0*blurSizeX, pointInTexture.y - 2.0*blurSizeY)) * 1/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 2.0*blurSizeX, pointInTexture.y - 2.0*blurSizeY)) * 3/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 1.0*blurSizeX, pointInTexture.y - 2.0*blurSizeY)) * 4/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 0.0*blurSizeX, pointInTexture.y - 2.0*blurSizeY)) * 5/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 1.0*blurSizeX, pointInTexture.y - 2.0*blurSizeY)) * 4/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 2.0*blurSizeX, pointInTexture.y - 2.0*blurSizeY)) * 3/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 3.0*blurSizeX, pointInTexture.y - 2.0*blurSizeY)) * 1/170;
//	
//	
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 3.0*blurSizeX, pointInTexture.y - 1.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 2.0*blurSizeX, pointInTexture.y - 1.0*blurSizeY)) * 4/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 1.0*blurSizeX, pointInTexture.y - 1.0*blurSizeY)) * 7/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 0.0*blurSizeX, pointInTexture.y - 1.0*blurSizeY)) * 8/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 1.0*blurSizeX, pointInTexture.y - 1.0*blurSizeY)) * 7/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 2.0*blurSizeX, pointInTexture.y - 1.0*blurSizeY)) * 4/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 3.0*blurSizeX, pointInTexture.y - 1.0*blurSizeY)) * 2/170;
//	
//	
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 3.0*blurSizeX, pointInTexture.y + 0.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 2.0*blurSizeX, pointInTexture.y + 0.0*blurSizeY)) * 5/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 1.0*blurSizeX, pointInTexture.y + 0.0*blurSizeY)) * 8/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 0.0*blurSizeX, pointInTexture.y + 0.0*blurSizeY)) * 10/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 1.0*blurSizeX, pointInTexture.y + 0.0*blurSizeY)) * 8/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 2.0*blurSizeX, pointInTexture.y + 0.0*blurSizeY)) * 5/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 3.0*blurSizeX, pointInTexture.y + 0.0*blurSizeY)) * 2/170;
//	
//	
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 3.0*blurSizeX, pointInTexture.y + 1.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 2.0*blurSizeX, pointInTexture.y + 1.0*blurSizeY)) * 4/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 1.0*blurSizeX, pointInTexture.y + 1.0*blurSizeY)) * 7/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 0.0*blurSizeX, pointInTexture.y + 1.0*blurSizeY)) * 8/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 1.0*blurSizeX, pointInTexture.y + 1.0*blurSizeY)) * 7/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 2.0*blurSizeX, pointInTexture.y + 1.0*blurSizeY)) * 4/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 3.0*blurSizeX, pointInTexture.y + 1.0*blurSizeY)) * 2/170;
//	
//	
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 3.0*blurSizeX, pointInTexture.y + 2.0*blurSizeY)) * 1/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 2.0*blurSizeX, pointInTexture.y + 2.0*blurSizeY)) * 3/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 1.0*blurSizeX, pointInTexture.y + 2.0*blurSizeY)) * 4/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 0.0*blurSizeX, pointInTexture.y + 2.0*blurSizeY)) * 5/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 1.0*blurSizeX, pointInTexture.y + 2.0*blurSizeY)) * 4/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 2.0*blurSizeX, pointInTexture.y + 2.0*blurSizeY)) * 3/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 3.0*blurSizeX, pointInTexture.y + 2.0*blurSizeY)) * 1/170;
//	
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 3.0*blurSizeX, pointInTexture.y + 3.0*blurSizeY)) * 1/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 2.0*blurSizeX, pointInTexture.y + 3.0*blurSizeY)) * 1/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x - 1.0*blurSizeX, pointInTexture.y + 3.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 0.0*blurSizeX, pointInTexture.y + 3.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 1.0*blurSizeX, pointInTexture.y + 3.0*blurSizeY)) * 2/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 2.0*blurSizeX, pointInTexture.y + 3.0*blurSizeY)) * 1/170;
//	sum += tex2D.sample(sampler2D, float2(pointInTexture.x + 3.0*blurSizeX, pointInTexture.y + 3.0*blurSizeY)) * 1/170;
//	
//	return sum;
//}

//
//  Guassian.metal
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 12/31/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

#include <metal_stdlib>


using namespace metal;

struct BlurTexCoordsIn {
	packed_float3 position;
	packed_float4 color;
	packed_float2 textureCoordinate;
};

struct BlurTexCoordsOut {
	float4 position [[position]];
	float4 color;
	float2 textureCoordinate;
};


/* Vertex Shaders
	------------------------------------------*/

vertex BlurTexCoordsOut horizontal_guassian_vertex(const device BlurTexCoordsIn *vertex_array [[ buffer(0) ]],
																	unsigned     int             vid           [[ vertex_id ]])
{
	BlurTexCoordsOut out;
	
	out.position = float4(vertex_array[vid].position * float3(-1.0, 1.0, 1.0), 1.0);
	out.color = vertex_array[vid].color;
	out.textureCoordinate = vertex_array[vid].textureCoordinate;

	return out;
}

vertex BlurTexCoordsOut vertical_guassian_vertex(const device BlurTexCoordsIn *vertex_array [[ buffer(0) ]],
																 unsigned     int             vid           [[ vertex_id ]])
{
	BlurTexCoordsOut out;
	
	out.position = float4(vertex_array[vid].position * float3(-1.0, 1.0, 1.0), 1.0);
	out.color = vertex_array[vid].color;
	out.textureCoordinate = vertex_array[vid].textureCoordinate;
	
	return out;
}


/* Fragment Shaders
	------------------------------------------*/

fragment float4 horizontal_guassian_fragment(BlurTexCoordsOut interpolated [[ stage_in ]],
															texture2d<float> tex2D        [[ texture(0) ]],
															sampler          sampler2D    [[ sampler(0) ]])
{
	float4 sum = float4(0.0);
	half offset[14];
	
	offset[ 0] = interpolated.textureCoordinate.x + -0.028;
	offset[ 1] = interpolated.textureCoordinate.x + -0.024;
	offset[ 2] = interpolated.textureCoordinate.x + -0.020;
	offset[ 3] = interpolated.textureCoordinate.x + -0.016;
	offset[ 4] = interpolated.textureCoordinate.x + -0.012;
	offset[ 5] = interpolated.textureCoordinate.x + -0.008;
	offset[ 6] = interpolated.textureCoordinate.x + -0.004;
	offset[ 7] = interpolated.textureCoordinate.x +  0.004;
	offset[ 8] = interpolated.textureCoordinate.x +  0.008;
	offset[ 9] = interpolated.textureCoordinate.x +  0.012;
	offset[10] = interpolated.textureCoordinate.x +  0.016;
	offset[11] = interpolated.textureCoordinate.x +  0.020;
	offset[12] = interpolated.textureCoordinate.x +  0.024;
	offset[13] = interpolated.textureCoordinate.x +  0.028;
	
	sum += tex2D.sample(sampler2D, float2(offset[ 0], interpolated.textureCoordinate.y)) * 0.0044299121055;
	sum += tex2D.sample(sampler2D, float2(offset[ 1], interpolated.textureCoordinate.y)) * 0.00895781211794;
	sum += tex2D.sample(sampler2D, float2(offset[ 2], interpolated.textureCoordinate.y)) * 0.0215963866053;
	sum += tex2D.sample(sampler2D, float2(offset[ 3], interpolated.textureCoordinate.y)) * 0.0443683338718;
	sum += tex2D.sample(sampler2D, float2(offset[ 4], interpolated.textureCoordinate.y)) * 0.0776744219933;
	sum += tex2D.sample(sampler2D, float2(offset[ 5], interpolated.textureCoordinate.y)) * 0.115876621105;
	sum += tex2D.sample(sampler2D, float2(offset[ 6], interpolated.textureCoordinate.y)) * 0.147308056121;
	sum += tex2D.sample(sampler2D, interpolated.textureCoordinate                      ) * 0.159576912161;
	sum += tex2D.sample(sampler2D, float2(offset[ 7], interpolated.textureCoordinate.y)) * 0.147308056121;
	sum += tex2D.sample(sampler2D, float2(offset[ 8], interpolated.textureCoordinate.y)) * 0.115876621105;
	sum += tex2D.sample(sampler2D, float2(offset[ 9], interpolated.textureCoordinate.y)) * 0.0776744219933;
	sum += tex2D.sample(sampler2D, float2(offset[10], interpolated.textureCoordinate.y)) * 0.0443683338718;
	sum += tex2D.sample(sampler2D, float2(offset[11], interpolated.textureCoordinate.y)) * 0.0215963866053;
	sum += tex2D.sample(sampler2D, float2(offset[12], interpolated.textureCoordinate.y)) * 0.00895781211794;
	sum += tex2D.sample(sampler2D, float2(offset[13], interpolated.textureCoordinate.y)) * 0.0044299121055;
	
	return sum;
}


fragment float4 vertical_guassian_fragment(BlurTexCoordsOut interpolated [[ stage_in ]],
														texture2d<float> tex2D        [[ texture(0) ]],
														sampler          sampler2D    [[ sampler(0) ]])
{
	float4 sum = float4(0.0);
	half offset[14];
	
	offset[ 0] = interpolated.textureCoordinate.y + -0.028;
	offset[ 1] = interpolated.textureCoordinate.y + -0.024;
	offset[ 2] = interpolated.textureCoordinate.y + -0.020;
	offset[ 3] = interpolated.textureCoordinate.y + -0.016;
	offset[ 4] = interpolated.textureCoordinate.y + -0.012;
	offset[ 5] = interpolated.textureCoordinate.y + -0.008;
	offset[ 6] = interpolated.textureCoordinate.y + -0.004;
	offset[ 7] = interpolated.textureCoordinate.y +  0.004;
	offset[ 8] = interpolated.textureCoordinate.y +  0.008;
	offset[ 9] = interpolated.textureCoordinate.y +  0.012;
	offset[10] = interpolated.textureCoordinate.y +  0.016;
	offset[11] = interpolated.textureCoordinate.y +  0.020;
	offset[12] = interpolated.textureCoordinate.y +  0.024;
	offset[13] = interpolated.textureCoordinate.y +  0.028;
	
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 0])) * 0.0044299121055;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 1])) * 0.00895781211794;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 2])) * 0.0215963866053;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 3])) * 0.0443683338718;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 4])) * 0.0776744219933;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 5])) * 0.115876621105;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 6])) * 0.147308056121;
	sum += tex2D.sample(sampler2D, interpolated.textureCoordinate                      ) * 0.159576912161;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 7])) * 0.147308056121;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 8])) * 0.115876621105;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[ 9])) * 0.0776744219933;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[10])) * 0.0443683338718;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[11])) * 0.0215963866053;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[12])) * 0.00895781211794;
	sum += tex2D.sample(sampler2D, float2(interpolated.textureCoordinate.x, offset[13])) * 0.0044299121055;
	
	return sum;
}


































// ============================== OLD STUFF BELOW ============================================================
// ===========================================================================================================
// ===========================================================================================================
// vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

//struct VertexIn {
//	packed_float3 position;
//	packed_float4 color;
//	packed_float2 textureCoordinate;
//};

//struct VertexOut {
//	float4 position [[position]];
//	float4 color;
//	float2 textureCoordinate;
//};
//
//struct Uniforms {
//	float4x4 modelMatrix;
//	float4x4 projectionMatrix;
//};

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


//kernel void horizontal_guassian(texture2d<float,access::read> inputTex [[ texture(0) ]],
//										  texture2d<float,access::write> outputTex [[ texture(1) ]],
//										  uint2 gid [[ thread_position_in_grid ]])
//{
//	float4 inColor = inputTex.read(gid);
//	outputTex.write(inColor, gid);
//}
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

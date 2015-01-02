//
//  Shaders.metal
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 11/27/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void basic_render(texture2d<float,access::read> inputTex [[ texture(0) ]],
								 texture2d<float,access::write> outputTex [[ texture(1) ]],
								 uint2 gid [[ thread_position_in_grid ]])
{
	float4 inColor = inputTex.read(gid);
	outputTex.write(inColor, gid);
}

//
//  Vertex.swift
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 11/27/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

struct Vertex{
	
	var x,y,z: Float
	var r,g,b,a: Float
	var s,t: Float
	
	func floatBuffer() -> [Float]{
		return [x,y,z,r,g,b,a,s,t]
	}
	
};

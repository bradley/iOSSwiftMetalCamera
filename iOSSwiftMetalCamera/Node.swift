//
//  Node.swift
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 11/27/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

import UIKit
import Metal
import QuartzCore
import GLKit.GLKMath

class Node: NSObject {
 
	let name: String
	var texture: MTLTexture?
	var samplerState: MTLSamplerState?
	var vertexCount: Int
	var vertexBuffer: MTLBuffer
	var uniformsBuffer: MTLBuffer?
	var device: MTLDevice
	
	var positionX:Float = 0.0
	var positionY:Float = 0.0
	var positionZ:Float = 0.0
 
	var rotationX:Float = 0.0
	var rotationY:Float = 0.0
	var rotationZ:Float = 0.0
	var scaleX:Float    = 1.0
	var scaleY:Float    = 1.0
	var scaleZ:Float    = 1.0
 
	init(name: String, vertices: Array<Vertex>, device: MTLDevice){
		var vertexData = Array<Float>()
		for vertex in vertices
		{
			vertexData += vertex.floatBuffer()
		}
		
		let dataSize = vertexData.count * sizeofValue(vertexData[0])
		
		self.name = name
		self.device = device
		vertexCount = vertices.count
		vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: nil)
		uniformsBuffer = device.newBufferWithLength(sizeof(Float)*16*2, options: nil)
		super.init()
	}
	
	func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4, clearColor: MTLClearColor?){
		
		let renderPassDescriptor = MTLRenderPassDescriptor()
		renderPassDescriptor.colorAttachments[0].texture = drawable.texture
		renderPassDescriptor.colorAttachments[0].loadAction = .Clear
		
		if let clearColor = clearColor{
			renderPassDescriptor.colorAttachments[0].clearColor = clearColor
		}
		else{
			renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1, blue: 1, alpha: 1.0)
		}
		
		renderPassDescriptor.colorAttachments[0].storeAction = .Store
		
		let commandBuffer = commandQueue.commandBuffer()
		
		let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)!
		renderEncoder.setRenderPipelineState(pipelineState)
		renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, atIndex: 0)
		
		if let texture = texture{
			renderEncoder.setFragmentTexture(self.texture, atIndex: 0)
		}
		
		if let samplerState = samplerState{
			renderEncoder.setFragmentSamplerState(samplerState, atIndex: 0)
		}
		
		//For now cull mode is used instead of depth buffer
		renderEncoder.setCullMode(MTLCullMode.None)
		
		//Setup uniform buffer
		var nodeModelMatrix: Matrix4 = self.modelMatrix()
		nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
		
		var bufferPointer = uniformsBuffer?.contents()
		memcpy(bufferPointer!, nodeModelMatrix.raw(), UInt(sizeof(Float)*16))
		memcpy(bufferPointer! + sizeof(Float)*16, projectionMatrix.raw(), UInt(sizeof(Float)*16))
		renderEncoder.setVertexBuffer(self.uniformsBuffer, offset: 0, atIndex: 1)
		
		//Draw primitives
		renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: self.vertexCount, instanceCount: self.vertexCount/3)
		renderEncoder.endEncoding()
		
		commandBuffer.presentDrawable(drawable)
		commandBuffer.commit()
	}
	
	func modelMatrix() -> Matrix4 {
		var matrix = Matrix4()
		matrix.translate(positionX, y: positionY, z: positionZ)
		matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
		matrix.scale(scaleX, y: scaleY, z: scaleZ)
		return matrix
	}
 
}
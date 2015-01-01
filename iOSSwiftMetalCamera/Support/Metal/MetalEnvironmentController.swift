//
//  MetalEnvironmentController.swift
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 11/27/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

import UIKit
import Metal
import QuartzCore


class MetalEnvironmentController: NSObject {
	
	var view: UIView
	
	var device: MTLDevice! = nil
	var metalLayer: CAMetalLayer! = nil
	
	var pipelineState: MTLRenderPipelineState! = nil
	var commandQueue: MTLCommandQueue! = nil
	var timer: CADisplayLink! = nil
	
	var projectionMatrix: Matrix4!
	var cameraXAngle: Float = 0.0
	var cameraYAngle: Float = 0.0
	var cameraZAngle: Float = 0.0
	
	var sceneObjects: [Node] = []
	
	
	/* Lifecycle
	------------------------------------------*/
	
	init(view: UIView) {
		self.view = view
		
		// Create reference to default metal device.
		device = MTLCreateSystemDefaultDevice()
	}
	
	
	/* Instance Methods
	------------------------------------------*/
	
	func run() {
		setupProjectionMatrix()
		setupMetalLayer()
		createCommandQueue()
		createDisplayLink()
	}
	
	func setupMetalLayer() {
		metalLayer = CAMetalLayer()
		metalLayer.device = device
		// Set pixel format. 8 bytes for Blue, Green, Red, and Alpha, in that order
		//   with normalized values between 0 and 1
		metalLayer.pixelFormat = .BGRA8Unorm
		metalLayer.framebufferOnly = false
		metalLayer.frame = view.layer.frame
		view.layer.addSublayer(metalLayer)
	}
	
	func setupProjectionMatrix() {
		projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0), aspectRatio: Float(view.bounds.size.width / view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
	}
	
	func createCommandQueue() {
		// A queue of commands for GPU to execute.
		commandQueue = device.newCommandQueue()
	}
	
	func createDisplayLink() {
		// Call gameloop() on every screen refresh.
		timer = CADisplayLink(target: self, selector: Selector("gameloop:"))
		timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
	}
	
	func render() {
		var drawable = metalLayer.nextDrawable()
		var worldModelMatrix = Matrix4()
		//worldModelMatrix.translate(0.0, y: 0.0, z: -5.0)
		//MARK! //worldModelMatrix.translate(0.0, y: 0.0, z: worldZFullVideo)
		worldModelMatrix.translate(0.0, y: 0.0, z: -1.456)
		worldModelMatrix.rotateAroundX(Matrix4.degreesToRad(cameraXAngle), y: Matrix4.degreesToRad(cameraYAngle), z: 0.0)
		
		// Enumerate over scene objects and render.
		if (sceneObjects.count > 0) {
			for (index, objectToDraw) in enumerate(sceneObjects) {
				objectToDraw.render(commandQueue, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix)
			}
		}
	}
 
	func gameloop(displayLink: CADisplayLink) {
		autoreleasepool {
			self.render()
		}
	}
	
	
	func pushObjectToScene(objectToDraw: Node) {
		sceneObjects.append(objectToDraw)
	}
	
}
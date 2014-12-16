//
//  ShaderView.swift
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 11/27/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

import UIKit
import Metal
import QuartzCore
import CoreMedia

class ShaderView: UIView {
	
	var device: MTLDevice! = nil
	var metalLayer: CAMetalLayer! = nil
	
	var objectToDraw: Plane!
	var pipelineState: MTLRenderPipelineState! = nil
	var commandQueue: MTLCommandQueue! = nil
	var timer: CADisplayLink! = nil
	
	var projectionMatrix: Matrix4!
	
	var textureWidth: UInt?
	var textureHeight: UInt?

	var unmanagedTextureCache: Unmanaged<CVMetalTextureCache>?
	var textureCache: CVMetalTextureCacheRef?
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		setup()
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setup()
	}
	
	func setup() {
		// Create reference to default metal device.
		device = MTLCreateSystemDefaultDevice()
		
		setupMetalLayer()
		setupProjectionMatrix()
		createRenderBuffer()
		createRenderPipeline()
		createCommandQueue()
		createDisplayLink()
		createTextureCache()
	}
	
	func setupMetalLayer() {
		metalLayer = CAMetalLayer()
		metalLayer.device = device
		// Set pixel format. 8 bytes for Blue, Green, Red, and Alpha, in that order
		//   with normalized values between 0 and 1
		metalLayer.pixelFormat = .BGRA8Unorm
		metalLayer.framebufferOnly = false
		metalLayer.frame = layer.frame
		layer.addSublayer(metalLayer)
	}
	
	func setupProjectionMatrix() {
		projectionMatrix = Matrix4()
	}
	
	func createRenderBuffer() {
		objectToDraw = Plane(device: device)

		var texture = METLTexture(resourceName: "black", ext: "png")
		texture.finalize(device, flip: false)
		objectToDraw.samplerState = generateSamplerStateForTexture(device)
		objectToDraw.texture = texture.texture
	}
	
	func generateSamplerStateForTexture(device: MTLDevice) -> MTLSamplerState? {
		var pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor();
		
		if let sampler = pSamplerDescriptor
		{
			sampler.minFilter             = MTLSamplerMinMagFilter.Nearest
			sampler.magFilter             = MTLSamplerMinMagFilter.Nearest
			sampler.mipFilter             = MTLSamplerMipFilter.NotMipmapped
			sampler.maxAnisotropy         = 1
			sampler.sAddressMode          = MTLSamplerAddressMode.ClampToEdge
			sampler.tAddressMode          = MTLSamplerAddressMode.ClampToEdge
			sampler.rAddressMode          = MTLSamplerAddressMode.ClampToEdge
			sampler.normalizedCoordinates = true
			sampler.lodMinClamp           = 0
			sampler.lodMaxClamp           = FLT_MAX
		}
		else
		{
			println(">> ERROR: Failed creating a sampler descriptor!")
		}
		
		return device.newSamplerStateWithDescriptor(pSamplerDescriptor!)
	}
	
	func createRenderPipeline() {
		// Access any of the precompiled shaders included in your project through the MTLLibrary by calling device.newDefaultLibrary().
		//   Then look up each shader by name.
		let defaultLibrary = device.newDefaultLibrary()!
		let fragmentProgram = defaultLibrary.newFunctionWithName("basic_fragment")
		let vertexProgram = defaultLibrary.newFunctionWithName("basic_vertex")
		
		
		//  Set up the render pipeline configuration here.
		//    This contains the shaders you want to use, and the pixel format for the color attachment
		let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
		pipelineStateDescriptor.vertexFunction = vertexProgram
		pipelineStateDescriptor.fragmentFunction = fragmentProgram
		pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
		
		// Compile the pipeline configuration into a pipeline state that is efficient to use here on out.
		var pipelineError : NSError?
		pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor, error: &pipelineError)
		if !(pipelineState != nil) {
			println("Failed to create pipeline state, error \(pipelineError)")
		}
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
	
	func createTextureCache() {
		//  Use a CVMetalTextureCache object to directly read from or write to GPU-based CoreVideo image buffers 
		//    in rendering or GPU compute tasks that use the Metal framework. For example, you can use a Metal 
		//    texture cache to present live output from a device’s camera in a 3D scene rendered with Metal.
		CVMetalTextureCacheCreate(nil, nil, device, nil, &unmanagedTextureCache)
		textureCache = unmanagedTextureCache!.takeRetainedValue()
	}
	
	func updateTextureFromSampleBuffer(sampleBuffer: CMSampleBuffer!) {
		var pixelBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
		var sourceImage: CIImage = CIImage(CVPixelBuffer: pixelBuffer)

		var sourceExtent: CGRect = sourceImage.extent()
		var sourceAspect: CGFloat = sourceExtent.size.width / sourceExtent.size.height
		var previewAspect: CGFloat = self.bounds.size.width  / self.bounds.size.height
		
		var drawRect: CGRect = sourceExtent
		
		if (sourceAspect > previewAspect) {
			// use full height of the video image, and center crop the width
			objectToDraw.positionX = Float(((sourceExtent.size.width - sourceExtent.size.height * previewAspect) / 2.0) / sourceExtent.size.width)
			objectToDraw.positionY = 0.0
			
			objectToDraw.scaleX = Float((drawRect.size.height * previewAspect) / sourceExtent.size.height)
			objectToDraw.scaleY = 1.0
		} else {
			// use full width of the video image, and center crop the height
			objectToDraw.positionX = 0.0
			objectToDraw.positionY = Float(((sourceExtent.size.height - sourceExtent.size.width / previewAspect) / 2.0) / sourceExtent.size.height);
			objectToDraw.scaleX = 1.0
			objectToDraw.scaleY = Float((sourceExtent.size.width / previewAspect) / sourceExtent.size.width)
		}

		var texture: MTLTexture
		
		textureWidth = CVPixelBufferGetWidth(pixelBuffer)
		textureHeight = CVPixelBufferGetHeight(pixelBuffer)

		var pixelFormat: MTLPixelFormat = MTLPixelFormat.BGRA8Unorm
		
		var unmanagedTexture: Unmanaged<CVMetalTexture>?
		var status: CVReturn = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, textureWidth!, textureHeight!, 0, &unmanagedTexture)
		//(0 == kCVReturnSuccess)
		if (status == 0) {
			texture = CVMetalTextureGetTexture(unmanagedTexture?.takeRetainedValue());
			objectToDraw.texture! = texture
	   }
		
	}
	
	func render() {
		var drawable = metalLayer.nextDrawable()
		var worldModelMatrix = Matrix4()
		
		objectToDraw.render(commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix ,clearColor: nil)
		drawable.texture
	}
 
	func gameloop(displayLink: CADisplayLink) {
		autoreleasepool {
			self.render()
		}
	}
	
}



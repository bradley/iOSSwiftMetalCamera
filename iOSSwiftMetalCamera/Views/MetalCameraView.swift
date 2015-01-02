//
//  MetalCameraView.swift
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 12/30/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

import CoreMedia

class MetalCameraView: UIView, NodeDelegate {

	var metalEnvironment: MetalEnvironmentController?
	var metalDevice: MTLDevice?
	
	var videoPlane: Plane?
	
	var basicVideoPlanePipeline: MTLComputePipelineState!
	var horizontalGuassianPipeline: MTLComputePipelineState!
	var compositePipeline: MTLRenderPipelineState!
	
	var textureWidth: UInt?
	var textureHeight: UInt?
	var unmanagedTextureCache: Unmanaged<CVMetalTextureCache>?
	var textureCache: CVMetalTextureCacheRef?
	let worldZFullVideo: Float = -1.456 // World model matrix z position for full-screen video plane.
	
	var videoOutputTexture: MTLTexture?
	
	var showShader:Bool = false
	
	
	/* Lifecycle
	------------------------------------------*/
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		setup()
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setup()
	}
	
	func setup() {
		setupMetalEnvironment()
		
		createTextureCache()
		createRenderBufferObjects()
		createRenderPipelineStates()
		createOutputTextureForVideoPlane()
		setListeners()
		
		metalEnvironment!.run()
	}
	
	
	/* Instance Methods
	------------------------------------------*/
	
	func setupMetalEnvironment() {
		metalEnvironment = MetalEnvironmentController(view: self)
		
		metalDevice = metalEnvironment!.device
	}
	
	func createTextureCache() {
		//  Use a CVMetalTextureCache object to directly read from or write to GPU-based CoreVideo image buffers
		//    in rendering or GPU compute tasks that use the Metal framework. For example, you can use a Metal
		//    texture cache to present live output from a device’s camera in a 3D scene rendered with Metal.
		CVMetalTextureCacheCreate(nil, nil, metalDevice, nil, &unmanagedTextureCache)
		
		textureCache = unmanagedTextureCache!.takeRetainedValue()
	}
	
	func createOutputTextureForVideoPlane() {
		var width = videoPlane!.texture?.width
		var height = videoPlane!.texture?.height
		var format = videoPlane!.texture?.pixelFormat
		var desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(format!, width: width!, height: height!, mipmapped: false)
		videoOutputTexture = metalDevice!.newTextureWithDescriptor(desc)
	}
	
	func createRenderBufferObjects() {
		// Create our scene objects.
		videoPlane = Plane(device: metalDevice!)
		videoPlane?.delegate = self
		
		var texture = METLTexture(resourceName: "black", ext: "png")
		texture.finalize(metalDevice!, flip: false)
		videoPlane!.samplerState = generateSamplerStateForTexture(metalDevice!)
		videoPlane!.texture = texture.texture
		
		metalEnvironment!.pushObjectToScene(videoPlane!)
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
	
	func createRenderPipelineStates() {
		// Access any of the precompiled shaders included in your project through the MTLLibrary by calling device.newDefaultLibrary().
		//   Then look up each shader by name.
		let defaultLibrary = metalDevice!.newDefaultLibrary()!

		// Load all shaders needed for render pipeline
		let basicRenderKernal = defaultLibrary.newFunctionWithName("basic_render")
		let horizontalGuassianKernal = defaultLibrary.newFunctionWithName("horizontal_guassian")
		let compositeVert = defaultLibrary.newFunctionWithName("composite_vertex")
		let compositeFrag = defaultLibrary.newFunctionWithName("composite_fragment")
		
		// Setup pipeline
		let desc = MTLRenderPipelineDescriptor()
		var pipelineError : NSError?
		
		desc.label = "Basic"
		desc.colorAttachments[0].pixelFormat = .BGRA8Unorm
		basicVideoPlanePipeline = metalDevice!.newComputePipelineStateWithFunction(basicRenderKernal!, error: &pipelineError)
		if !(basicVideoPlanePipeline != nil) {
			println("Failed to create pipeline state, error \(pipelineError)")
		}
		
		desc.label = "Horizontal Guassian"
		desc.colorAttachments[0].pixelFormat = .BGRA8Unorm
		horizontalGuassianPipeline = metalDevice!.newComputePipelineStateWithFunction(horizontalGuassianKernal!, error: &pipelineError)
		if !(horizontalGuassianPipeline != nil) {
			println("Failed to create pipeline state, error \(pipelineError)")
		}
		
		desc.label = "Composite"
		desc.vertexFunction = compositeVert
		desc.fragmentFunction = compositeFrag
		desc.colorAttachments[0].pixelFormat = .BGRA8Unorm
		compositePipeline = metalDevice!.newRenderPipelineStateWithDescriptor(desc, error: &pipelineError)
		if !(horizontalGuassianPipeline != nil) {
			println("Failed to create pipeline state, error \(pipelineError)")
		}
	}
	
	func updateTextureFromSampleBuffer(sampleBuffer: CMSampleBuffer!) {
		var pixelBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
		var sourceImage: CIImage = CIImage(CVPixelBuffer: pixelBuffer)
		
		var sourceExtent: CGRect = sourceImage.extent()
		var sourceAspect: CGFloat = sourceExtent.size.width / sourceExtent.size.height
		var previewAspect: CGFloat = self.bounds.size.width  / self.bounds.size.height
		
		if (sourceAspect > previewAspect) {
			videoPlane!.scaleX = Float(sourceAspect)
			videoPlane!.scaleY = 1.0
		} else {
			videoPlane!.scaleX = 1.0
			videoPlane!.scaleY = Float(1.0 / sourceAspect)
		}
		
		var texture: MTLTexture
		
		textureWidth = CVPixelBufferGetWidth(pixelBuffer)
		textureHeight = CVPixelBufferGetHeight(pixelBuffer)
		
		var pixelFormat: MTLPixelFormat = MTLPixelFormat.BGRA8Unorm
		
		var unmanagedTexture: Unmanaged<CVMetalTexture>?
		var status: CVReturn = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, textureWidth!, textureHeight!, 0, &unmanagedTexture)
		//Note: 0 = kCVReturnSuccess
		if (status == 0) {
			texture = CVMetalTextureGetTexture(unmanagedTexture?.takeRetainedValue());
			videoPlane!.texture! = texture
		}
	}
	
	func setListeners() {
		let panRecognizer = UIPanGestureRecognizer(target: self, action: "panGesture:")
		self.addGestureRecognizer(panRecognizer)
	}
	
	func panGesture(sender: UIPanGestureRecognizer) {
		let translation = sender.translationInView(sender.view!)
		var newXAngle = (Float)(translation.y)*(Float)(M_PI)/180.0
		metalEnvironment!.cameraXAngle += newXAngle
		
		var newYAngle = (Float)(translation.x)*(Float)(M_PI)/180.0
		metalEnvironment!.cameraYAngle += newYAngle
	}
	
	func toggleShader(shouldShowShader: Bool) {
		showShader = shouldShowShader
	}
	
	
	/* Delegate Methods
	------------------------------------------*/
	
	// TODO: This descriptor doesn't change between renders as far as I know. Maybe this could be improved.
	func renderPassDescriptorForNode(node: Node, drawable: CAMetalDrawable) -> MTLRenderPassDescriptor {
		var desc: MTLRenderPassDescriptor?
		
		if (node == videoPlane) {
			desc = MTLRenderPassDescriptor()
			desc!.colorAttachments[0].texture = drawable.texture
			desc!.colorAttachments[0].loadAction = .Clear
			desc!.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1, blue: 1, alpha: 1.0)
			desc!.colorAttachments[0].storeAction = .Store
		}
		
		return desc!
	}
	
	func configureComputeEncoderForNode(node: Node, encoder: MTLComputeCommandEncoder, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4) {
		
		if (node == videoPlane) {
			
			createOutputTextureForVideoPlane()

			// Kernel function programming relies on breaking the workload into chunks (threadgroups) that can
			//   be executed in parallel on the GPU. Here we essentially break our image data into 64 chunks for the GPU
			//   to process.
			var threadgroupCounts = MTLSizeMake(8, 8, 1);
			var width = videoPlane?.texture?.width
			var height = videoPlane?.texture?.height
			var threadgroups = MTLSizeMake(width! / threadgroupCounts.width, height! / threadgroupCounts.height, 1);

			
			/* Base Encoding
			------------------------------------------*/
			encoder.pushDebugGroup("Basic render")
			encoder.setComputePipelineState(basicVideoPlanePipeline!)
			encoder.setTexture(videoPlane!.texture!, atIndex: 0)
			encoder.setTexture(videoOutputTexture, atIndex: 1)
			encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
			
			encoder.popDebugGroup()
			/* ---------------------------------------*/
			
			/* Horizontal Guassian Blur Encoding
			------------------------------------------*/
			encoder.pushDebugGroup("Horizontal Guassian render")
			encoder.setComputePipelineState(horizontalGuassianPipeline!)
			encoder.setTexture(videoOutputTexture, atIndex: 0)
			encoder.setTexture(videoOutputTexture, atIndex: 1)
			encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
			encoder.popDebugGroup()
			
			
			encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
			/* ---------------------------------------*/
		}
	}
	
	func configureRenderEncoderForNode(node: Node, encoder: MTLRenderCommandEncoder, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4) {
		
		if (node == videoPlane) {
			
			/* Composite Render Encoding
			------------------------------------------*/
			encoder.pushDebugGroup("Composite render")
			encoder.setRenderPipelineState(compositePipeline!)
			encoder.setVertexBuffer(videoPlane!.vertexBuffer, offset: 0, atIndex: 0)
			encoder.setFragmentTexture(videoOutputTexture, atIndex: 0)
			encoder.setFragmentSamplerState(videoPlane!.samplerState!, atIndex: 0)
			encoder.setCullMode(MTLCullMode.None)
			
//			// Set metadata buffer
//			var metaDataBuffer = metalDevice!.newBufferWithBytes(&showShader, length: 1, options: MTLResourceOptions.OptionCPUCacheModeDefault)
//			encoder.setFragmentBuffer(metaDataBuffer, offset: 0, atIndex: 0)
			
			// Setup uniform buffer
			// Convert the convenience properties (like position and rotation) into a model matrix
			var nodeModelMatrix: Matrix4 = videoPlane!.modelMatrix()
			nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
			// Get a raw pointer from buffer.
			var bufferPointer = videoPlane!.uniformsBuffer?.contents()
			// Copy your matrix data into the buffer
			memcpy(bufferPointer!, nodeModelMatrix.raw(), UInt(sizeof(Float)*16))
			memcpy(bufferPointer! + sizeof(Float)*16, projectionMatrix.raw(), UInt(sizeof(Float)*16))
			// Pass uniformBuffer (with data copied) to the vertex shader
			encoder.setVertexBuffer(videoPlane!.uniformsBuffer, offset: 0, atIndex: 1)
			
			// Draw primitives
			encoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: videoPlane!.vertexCount, instanceCount: videoPlane!.vertexCount / 3)
			encoder.popDebugGroup()
			/* ---------------------------------------*/
		}
	}
	
}
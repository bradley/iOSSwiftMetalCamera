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
	
	var rgbShiftPipeline: MTLRenderPipelineState!
	var compositePipeline: MTLRenderPipelineState!
	var horizontalGuassianPipeline: MTLRenderPipelineState!
	var verticalGuassianPipeline: MTLRenderPipelineState!
	
	var textureWidth: UInt?
	var textureHeight: UInt?
	var unmanagedTextureCache: Unmanaged<CVMetalTextureCache>?
	var textureCache: CVMetalTextureCacheRef?
	let worldZFullVideo: Float = -1.456 // World model matrix z position for full-screen video plane.
	
	var videoOutputTexture: MTLTexture?
	var videoTextureBuffer: MTLRenderPassDescriptor?
	var horizontalGuassianTexture: MTLTexture?
	var horizontalGuassianBuffer: MTLRenderPassDescriptor?
	var verticalGuassianTexture: MTLTexture?
	var verticalGuassianBuffer: MTLRenderPassDescriptor?
	var currentFrameBuffer: MTLRenderPassDescriptor?
	
	var showShader:Bool = false
	
	
	/* Lifecycle
	------------------------------------------*/
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		_setup()
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		_setup()
	}
	
	private func _setup() {
		_setupMetalEnvironment()
		
		_createTextureCache()
		_createRenderBufferObjects()
		_createRenderPipelineStates()
		_createOutputTextureForVideoPlane()
		_createOutputTexturesForGuassian()
		_setListeners()
		
		metalEnvironment!.run()
	}
	
	
	/* Private Instance Methods
	------------------------------------------*/
	
	private func _setupMetalEnvironment() {
		metalEnvironment = MetalEnvironmentController(view: self)
		
		metalDevice = metalEnvironment!.device
	}
	
	private func _createTextureCache() {
		//  Use a CVMetalTextureCache object to directly read from or write to GPU-based CoreVideo image buffers
		//    in rendering or GPU compute tasks that use the Metal framework. For example, you can use a Metal
		//    texture cache to present live output from a device’s camera in a 3D scene rendered with Metal.
		CVMetalTextureCacheCreate(nil, nil, metalDevice, nil, &unmanagedTextureCache)
		
		textureCache = unmanagedTextureCache!.takeRetainedValue()
	}
	
	private func _createOutputTextureForVideoPlane() {
		let width = 1280
		let height = 720
		let format = videoPlane!.texture?.pixelFormat
		let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(format!, width: width, height: height, mipmapped: true)
		videoOutputTexture = metalDevice!.newTextureWithDescriptor(desc)

		videoTextureBuffer = MTLRenderPassDescriptor()
		videoTextureBuffer!.colorAttachments[0].texture = videoOutputTexture
		videoTextureBuffer!.colorAttachments[0].loadAction = MTLLoadAction.Load
		videoTextureBuffer!.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
		videoTextureBuffer!.colorAttachments[0].storeAction = MTLStoreAction.Store
	}
	
	private func _createOutputTexturesForGuassian() {
		let width = 1280
		let height = 720
		let format = videoPlane!.texture?.pixelFormat
		let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(format!, width: width, height: height, mipmapped: true)
		horizontalGuassianTexture = metalDevice!.newTextureWithDescriptor(desc)
		verticalGuassianTexture = metalDevice!.newTextureWithDescriptor(desc)
		
		horizontalGuassianBuffer = MTLRenderPassDescriptor()
		horizontalGuassianBuffer!.colorAttachments[0].texture = horizontalGuassianTexture
		horizontalGuassianBuffer!.colorAttachments[0].loadAction = MTLLoadAction.Load
		horizontalGuassianBuffer!.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
		horizontalGuassianBuffer!.colorAttachments[0].storeAction = MTLStoreAction.Store
		
		verticalGuassianBuffer = MTLRenderPassDescriptor()
		verticalGuassianBuffer!.colorAttachments[0].texture = verticalGuassianTexture
		verticalGuassianBuffer!.colorAttachments[0].loadAction = MTLLoadAction.Load
		verticalGuassianBuffer!.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
		verticalGuassianBuffer!.colorAttachments[0].storeAction = MTLStoreAction.Store
	}
	
	private func _createRenderBufferObjects() {
		// Create our scene objects.
		videoPlane = Plane(device: metalDevice!)
		videoPlane?.delegate = self

		var texture = METLTexture(resourceName: "black", ext: "png")
		texture.format = MTLPixelFormat.BGRA8Unorm
		texture.finalize(metalDevice!, flip: false)
		videoPlane!.samplerState = _generateSamplerStateForTexture(metalDevice!)
		videoPlane!.texture = texture.texture
		
		metalEnvironment!.pushObjectToScene(videoPlane!)
	}
	
	private func _generateSamplerStateForTexture(device: MTLDevice) -> MTLSamplerState? {
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
	
	private func _createRenderPipelineStates() {
		// Access any of the precompiled shaders included in your project through the MTLLibrary by calling device.newDefaultLibrary().
		//   Then look up each shader by name.
		let defaultLibrary = metalDevice!.newDefaultLibrary()!

		// Load all shaders needed for render pipeline
		let basicVert = defaultLibrary.newFunctionWithName("basic_vertex")
		let rgbShiftFrag = defaultLibrary.newFunctionWithName("rgb_shift_fragment")
		let compositeVert = defaultLibrary.newFunctionWithName("composite_vertex")
		let compositeFrag = defaultLibrary.newFunctionWithName("composite_fragment")
		let horizontalGuasVert = defaultLibrary.newFunctionWithName("horizontal_guassian_vertex")
		let horizontalGuasFrag = defaultLibrary.newFunctionWithName("horizontal_guassian_fragment")
		let verticalGuasVert = defaultLibrary.newFunctionWithName("vertical_guassian_vertex")
		let verticalGuasFrag = defaultLibrary.newFunctionWithName("vertical_guassian_fragment")
		
		// Setup pipeline
		let desc = MTLRenderPipelineDescriptor()
		var pipelineError : NSError?
		
		desc.label = "Composite"
		desc.vertexFunction = compositeVert
		desc.fragmentFunction = compositeFrag
		desc.colorAttachments[0].pixelFormat = .BGRA8Unorm
		compositePipeline = metalDevice!.newRenderPipelineStateWithDescriptor(desc, error: &pipelineError)
		if !(compositePipeline != nil) {
			println("Failed to create pipeline state, error \(pipelineError)")
		}
		
		desc.label = "RGBShift"
		desc.vertexFunction = basicVert
		desc.fragmentFunction = rgbShiftFrag
		desc.colorAttachments[0].pixelFormat = .BGRA8Unorm
		rgbShiftPipeline = metalDevice!.newRenderPipelineStateWithDescriptor(desc, error: &pipelineError)
		if !(rgbShiftPipeline != nil) {
			println("Failed to create pipeline state, error \(pipelineError)")
		}
		
		desc.label = "HorizontalGuassian"
		desc.vertexFunction = horizontalGuasVert
		desc.fragmentFunction = horizontalGuasFrag
		desc.colorAttachments[0].pixelFormat = .BGRA8Unorm
		horizontalGuassianPipeline = metalDevice!.newRenderPipelineStateWithDescriptor(desc, error: &pipelineError)
		if !(horizontalGuassianPipeline != nil) {
			println("Failed to create pipeline state, error \(pipelineError)")
		}
		
		desc.label = "VerticalGuassian"
		desc.vertexFunction = verticalGuasVert
		desc.fragmentFunction = verticalGuasFrag
		desc.colorAttachments[0].pixelFormat = .BGRA8Unorm
		verticalGuassianPipeline = metalDevice!.newRenderPipelineStateWithDescriptor(desc, error: &pipelineError)
		if !(verticalGuassianPipeline != nil) {
			println("Failed to create pipeline state, error \(pipelineError)")
		}
	}
	
	private func _setListeners() {
		let panRecognizer = UIPanGestureRecognizer(target: self, action: "panGesture:")
		self.addGestureRecognizer(panRecognizer)
	}
	
	private func _currentFrameBufferForDrawable(drawable: CAMetalDrawable) -> MTLRenderPassDescriptor {
		if (currentFrameBuffer == nil) {
			currentFrameBuffer = MTLRenderPassDescriptor()
			currentFrameBuffer!.colorAttachments[0].texture = drawable.texture
			currentFrameBuffer!.colorAttachments[0].loadAction = MTLLoadAction.Clear
			currentFrameBuffer!.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
			currentFrameBuffer!.colorAttachments[0].storeAction = MTLStoreAction.Store
		}
		
		return currentFrameBuffer!
	}
	
	private func _configureComputeEncoders(commandBuffer: MTLCommandBuffer, node: Node, drawable: CAMetalDrawable) {
	}
	
	private func _configureRenderEncoders(commandBuffer: MTLCommandBuffer, node: Node, drawable: CAMetalDrawable) {
		if (node == videoPlane) {
			
			// Start first pass
			var firstPassEncoder = commandBuffer.renderCommandEncoderWithDescriptor(videoTextureBuffer!)!
			
			/* Test Render Encoding
			------------------------------------------*/
			firstPassEncoder.pushDebugGroup("RGBShift render")
			firstPassEncoder.setRenderPipelineState(rgbShiftPipeline!)
			firstPassEncoder.setVertexBuffer(videoPlane!.vertexBuffer, offset: 0, atIndex: 0)
			firstPassEncoder.setFragmentTexture(videoPlane?.texture, atIndex: 0)
			firstPassEncoder.setFragmentSamplerState(videoPlane!.samplerState!, atIndex: 0)
			firstPassEncoder.setCullMode(MTLCullMode.None)
			
			// Set metadata buffer
			var toggleBuffer = metalDevice!.newBufferWithBytes(&showShader, length: 1, options: MTLResourceOptions.OptionCPUCacheModeDefault)
			firstPassEncoder.setFragmentBuffer(toggleBuffer, offset: 0, atIndex: 0)
			
			// Draw primitives
			firstPassEncoder.drawPrimitives(
				.Triangle,
				vertexStart: 0,
				vertexCount: videoPlane!.vertexCount,
				instanceCount: videoPlane!.vertexCount / 3
			)
			
			firstPassEncoder.popDebugGroup()
			/* ---------------------------------------*/
			
			firstPassEncoder.endEncoding()
			
			
			
			
			
			
			// Start second pass
			var secondPassEncoder = commandBuffer.renderCommandEncoderWithDescriptor(horizontalGuassianBuffer!)!
			
			/* Test Render Encoding
			------------------------------------------*/
			secondPassEncoder.pushDebugGroup("HorizontalGuassian render")
			secondPassEncoder.setRenderPipelineState(horizontalGuassianPipeline!)
			secondPassEncoder.setVertexBuffer(videoPlane!.vertexBuffer, offset: 0, atIndex: 0)
			secondPassEncoder.setFragmentTexture(videoOutputTexture, atIndex: 0)
			secondPassEncoder.setFragmentSamplerState(videoPlane!.samplerState!, atIndex: 0)
			secondPassEncoder.setCullMode(MTLCullMode.None)
			
			// Draw primitives
			secondPassEncoder.drawPrimitives(
				.Triangle,
				vertexStart: 0,
				vertexCount: videoPlane!.vertexCount,
				instanceCount: videoPlane!.vertexCount / 3
			)
			
			secondPassEncoder.popDebugGroup()
			/* ---------------------------------------*/
			
			secondPassEncoder.endEncoding()
			
			
			
			
			
			
			
			// Start third pass
			var thirdPassEncoder = commandBuffer.renderCommandEncoderWithDescriptor(verticalGuassianBuffer!)!
			
			/* Test Render Encoding
			------------------------------------------*/
			thirdPassEncoder.pushDebugGroup("HorizontalGuassian render")
			thirdPassEncoder.setRenderPipelineState(verticalGuassianPipeline!)
			thirdPassEncoder.setVertexBuffer(videoPlane!.vertexBuffer, offset: 0, atIndex: 0)
			thirdPassEncoder.setFragmentTexture(horizontalGuassianTexture, atIndex: 0)
			thirdPassEncoder.setFragmentSamplerState(videoPlane!.samplerState!, atIndex: 0)
			thirdPassEncoder.setCullMode(MTLCullMode.None)
			
			// Draw primitives
			thirdPassEncoder.drawPrimitives(
				.Triangle,
				vertexStart: 0,
				vertexCount: videoPlane!.vertexCount,
				instanceCount: videoPlane!.vertexCount / 3
			)
			
			thirdPassEncoder.popDebugGroup()
			/* ---------------------------------------*/
			
			thirdPassEncoder.endEncoding()
			
			
			
			
			
			
			
			// Start fourth pass
			var fourthPassEncoder = commandBuffer.renderCommandEncoderWithDescriptor(_currentFrameBufferForDrawable(drawable))!
			
			/* Composite Render Encoding
			------------------------------------------*/
			fourthPassEncoder.pushDebugGroup("Composite render")
			fourthPassEncoder.setRenderPipelineState(compositePipeline!)
			fourthPassEncoder.setVertexBuffer(videoPlane!.vertexBuffer, offset: 0, atIndex: 0)
			fourthPassEncoder.setFragmentTexture(verticalGuassianTexture, atIndex: 0)
			fourthPassEncoder.setFragmentSamplerState(videoPlane!.samplerState!, atIndex: 0)
			fourthPassEncoder.setCullMode(MTLCullMode.None)
			
			// Setup uniform buffer
			var worldMatrix = metalEnvironment?.worldModelMatrix
			var projectionMatrix = metalEnvironment?.projectionMatrix
			fourthPassEncoder.setVertexBuffer(videoPlane?.sceneAdjustedUniformsBufferForworldModelMatrix(worldMatrix!, projectionMatrix: projectionMatrix!), offset: 0, atIndex: 1)
			
			// Draw primitives
			fourthPassEncoder.drawPrimitives(
				.Triangle,
				vertexStart: 0,
				vertexCount: videoPlane!.vertexCount,
				instanceCount: videoPlane!.vertexCount / 3
			)
			
			fourthPassEncoder.popDebugGroup()
			/* ---------------------------------------*/
			
			fourthPassEncoder.endEncoding()
			
			
			//videoTextureBuffer = nil
			currentFrameBuffer = nil
		}
	}
	
	
	/* Public Instance Methods
	------------------------------------------*/
	
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
		videoPlane!.positionZ = worldZFullVideo
		
		var texture: MTLTexture
		
		textureWidth = CVPixelBufferGetWidth(pixelBuffer)
		textureHeight = CVPixelBufferGetHeight(pixelBuffer)
		
		var pixelFormat: MTLPixelFormat = MTLPixelFormat.BGRA8Unorm
		
		var unmanagedTexture: Unmanaged<CVMetalTexture>?
		var status: CVReturn = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, textureWidth!, textureHeight!, 0, &unmanagedTexture)
		// Note: 0 = kCVReturnSuccess
		if (status == 0) {
			texture = CVMetalTextureGetTexture(unmanagedTexture?.takeRetainedValue());
			videoPlane!.texture! = texture
		}
	}
	
	
	/* NodeDelegate Delegate Methods
	------------------------------------------*/
	
	func configureCommandBuffer(commandBuffer: MTLCommandBuffer, node: Node, drawable: CAMetalDrawable) {
		_configureComputeEncoders(commandBuffer, node: node, drawable: drawable)
		_configureRenderEncoders(commandBuffer, node: node, drawable: drawable)
	}
	
}
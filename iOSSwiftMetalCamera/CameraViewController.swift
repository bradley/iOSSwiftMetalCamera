//
//  CameraViewController.swift
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 11/27/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

import UIKit
import CoreMedia
import AVFoundation

class CameraViewController: UIViewController, CameraSessionControllerDelegate {
	
	var cameraSessionController: CameraSessionController!
	var previewLayer: AVCaptureVideoPreviewLayer!
	var shaderView: ShaderView!
	
	@IBOutlet weak var shaderToggler: UISwitch!
	
	/* Lifecycle
	------------------------------------------*/
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupShaderView()
		cameraSessionController = CameraSessionController()
		cameraSessionController.sessionDelegate = self
		//setupPreviewLayer()
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		cameraSessionController.startCamera()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		
		cameraSessionController.teardownCamera()
	}

	
	/* Instance Methods
	------------------------------------------*/
	
	func setupPreviewLayer() {
		self.previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraSessionController.session)
		self.previewLayer.bounds = self.view.bounds
		self.previewLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
		self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		self.previewLayer.backgroundColor = UIColor.blackColor().CGColor // UNNECESSARY PROBABLY
		self.view.layer.addSublayer(self.previewLayer)
	}
	
	func setupShaderView() {
		var rect: CGRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.bounds.width, height: view.bounds.height))
		shaderView = ShaderView(frame: view.bounds)
		view.insertSubview(shaderView, atIndex: 0)
	}
	
	@IBAction func toggleShader(sender: AnyObject) {
		shaderView?.toggleShader(shaderToggler!.on)
	}
	
	/* Delegate Methods
	------------------------------------------*/
	
	func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
		if (connection.supportsVideoOrientation) {
			// NOTE: Video comes in upside down and mirrored when using the front camera.
			//   Rather than manually rotating it, setting orientation to PortraitUpsideDown here
			//   is a simple and efficient solution.
			connection.videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
		}
		if (connection.supportsVideoMirroring) {
			connection.videoMirrored = true
		}
		
		shaderView.updateTextureFromSampleBuffer(sampleBuffer)
	}

}


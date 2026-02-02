//
//  FaceRecognitionViewController.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 10.01.24.
//

import UIKit
import AVFoundation
import MetalKit

final class FaceRecognitionViewController: UIViewController {
    var captureDetector: FaceCaptureDetector?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let session = AVCaptureSession()
    private var metalDevice: MTLDevice?
    private var metalCommandQueue: MTLCommandQueue?
    private var metalView: MTKView?
    private var ciContext: CIContext?
    
    private var currentCIImage: CIImage? {
        didSet {
            metalView?.draw()
        }
    }
    
    private let videoOutputQueue = DispatchQueue(
        label: "Video Output Queue",
        qos: .userInitiated
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        captureDetector?.detectorDelegate = self
        configureMetal()
        configureCaptureSession()
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureDetector?.detectorDelegate = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        metalView?.frame = view.bounds
    }
}

// MARK: - Private Extension

private extension FaceRecognitionViewController {
    func configureCaptureSession() {
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            debugPrint("No front video camera available")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(cameraInput) {
                session.addInput(cameraInput)
            }
        } catch {
            debugPrint("Failed to create capture device input: \(error)")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(
            captureDetector,
            queue: videoOutputQueue
        )
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspect
        previewLayer?.frame = view.bounds
        
        if let previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
    }
    
    func configureMetal() {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            debugPrint("Metal is not supported on this device")
            return
        }
        
        metalCommandQueue = metalDevice.makeCommandQueue()
        
        metalView = MTKView()
        if let metalView {
            metalView.device = metalDevice
            metalView.isPaused = true
            metalView.enableSetNeedsDisplay = false
            metalView.delegate = self
            metalView.framebufferOnly = false
            metalView.frame = view.bounds
            metalView.layer.contentsGravity = .resizeAspect
            view.layer.insertSublayer(metalView.layer, at: 1)
        }
        
        ciContext = CIContext(mtlDevice: metalDevice)
    }
}

// MARK: - MTKViewDelegate Extension

extension FaceRecognitionViewController: MTKViewDelegate {
    func draw(in view: MTKView) {
        guard
            let metalView = metalView,
            let metalCommandQueue = metalCommandQueue,
            let commandBuffer = metalCommandQueue.makeCommandBuffer(),
            let ciImage = currentCIImage,
            let currentDrawable = view.currentDrawable
        else { return }
        
        let drawSize = metalView.drawableSize
        let scaleX = drawSize.width / ciImage.extent.width
        let newImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleX))
        let originY = (newImage.extent.height - drawSize.height) / 2
        
        ciContext?.render(
            newImage,
            to: currentDrawable.texture,
            commandBuffer: commandBuffer,
            bounds: CGRect(x: 0, y: originY,
                          width: newImage.extent.width,
                          height: newImage.extent.height),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
}

// MARK: - DetectorDelegate Extension

extension FaceRecognitionViewController: DetectorDelegate {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
        guard let previewLayer else { return .zero }
        
        return previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
    }
    
    func draw(image: CIImage) {
        currentCIImage = image
    }
}

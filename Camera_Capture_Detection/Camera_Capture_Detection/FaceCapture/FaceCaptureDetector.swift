//
//  FaceCaptureDetector.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 10.01.24.
//

import Foundation
import Vision
import CoreImage
import UIKit
import AVFoundation
import Combine

protocol DetectorDelegate: NSObjectProtocol {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
    func draw(image: CIImage)
}

final class FaceCaptureDetector: NSObject {
    weak var detectorDelegate: DetectorDelegate?
    weak var model: (any FaceRecognitionViewModelProtocol)?
    
    private var sequenceHandler = VNSequenceRequestHandler()
    private var isCapturingPhoto = false
    private var currentFrameBuffer: CVImageBuffer?
    private var subscriptions = Set<AnyCancellable>()
    
    private let imageProcessingQueue = DispatchQueue(
        label: "Image Processing Queue",
        qos: .userInitiated
    )
    
    func setupModelBinding() {
        guard let model = model as? FaceRecognitionViewModel else { return }
        
        model.shutterReleased
            .sink { [weak self] in
                self?.isCapturingPhoto = true
            }
            .store(in: &subscriptions)
    }
}

private extension FaceCaptureDetector {
    
    func processFaceObservation(_ result: VNFaceObservation) {
        guard
            let model,
            let viewDelegate = detectorDelegate
        else { return }
        
        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        let faceObservationModel = FaceGeometryModel(
            boundingBox: convertedBoundingBox,
            roll: result.roll ?? 0,
            pitch: result.pitch ?? 0,
            yaw: result.yaw ?? 0
        )
        
        DispatchQueue.main.async {
            model.perform(action: .faceObservationDetected(faceObservationModel))
        }
    }
    
    func processFaceQuality(_ result: VNFaceObservation) {
        guard let model else { return }
        
        let faceQualityModel = FaceQualityModel(
            quality: result.faceCaptureQuality ?? 0
        )
        
        DispatchQueue.main.async {
            model.perform(action: .faceQualityObservationDetected(faceQualityModel))
        }
    }
    
    func processSegmentation() {
        guard let currentFrameBuffer else { return }
        
        let originalImage = CIImage(cvImageBuffer: currentFrameBuffer)
            .oriented(.upMirrored)
        DispatchQueue.main.async {
            self.detectorDelegate?.draw(image: originalImage)
        }
    }
    
    func capturePhoto(
        from pixelBuffer: CVPixelBuffer,
        completion: @escaping (UIImage?) -> Void
    ) {
        imageProcessingQueue.async {
            let context = CIContext()
            let originalImage = CIImage(cvPixelBuffer: pixelBuffer)
            let coreImageWidth = originalImage.extent.width
            let coreImageHeight = originalImage.extent.height
            
            let desiredImageHeight = coreImageWidth * 4 / 3
            let yOrigin = (coreImageHeight - desiredImageHeight) / 2
            let photoRect = CGRect(x: 0, y: yOrigin, width: coreImageWidth, height: desiredImageHeight)
            
            guard
                let cgImage = context.createCGImage(originalImage, from: photoRect)
            else {
                completion(nil)
                return
            }
            
            let image = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)
            completion(image)
        }
    }
    
    func handleFaceDetection(
        request: VNRequest,
        error: Error?
    ) {
        guard let results = request.results as? [VNFaceObservation] else {
            DispatchQueue.main.async {
                self.model?.perform(action: .noFaceDetected)
            }
            return
        }
        
        if let result = results.first {
            processFaceObservation(result)
        } else {
            DispatchQueue.main.async {
                self.model?.perform(action: .noFaceDetected)
            }
        }
    }
    
    func handleFaceQuality(request: VNRequest, error: Error?) {
        guard
            let results = request.results as? [VNFaceObservation],
            let result = results.first
        else { return }
        
        processFaceQuality(result)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate Extension

extension FaceCaptureDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        
        let requests = [
            VNDetectFaceRectanglesRequest { [weak self] request, error in
                self?.handleFaceDetection(request: request, error: error)
            },
            VNDetectFaceCaptureQualityRequest { [weak self] request, error in
                self?.handleFaceQuality(request: request, error: error)
            }
        ]
        
        if isCapturingPhoto {
            isCapturingPhoto = false
            capturePhoto(from: imageBuffer) { [weak self] photo in
                guard let self, let photo else { return }
                
                DispatchQueue.main.async {
                    self.model?.perform(action: .sendSelfiePhoto(photo))
                }
            }
        }
        
        currentFrameBuffer = imageBuffer
        try? sequenceHandler.perform(requests, on: imageBuffer, orientation: .leftMirrored)
    }
}

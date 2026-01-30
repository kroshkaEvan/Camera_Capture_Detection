//
//  FaceCameraView.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 30.01.24.
//

import SwiftUI

struct FaceCameraView<Model>: UIViewControllerRepresentable where Model: FaceRecognitionViewModelProtocol {
    private let model: Model
    
    init(model: Model) {
        self.model = model
    }
    
    func makeUIViewController(context: Context) -> FaceRecognitionViewController {
        let faceDetector = FaceCaptureDetector()
        faceDetector.model = model
        faceDetector.setupModelBinding()
        
        let viewController = FaceRecognitionViewController()
        viewController.captureDetector = faceDetector
        
        return viewController
    }
    
    func updateUIViewController(
        _ uiViewController: FaceRecognitionViewController,
        context: Context
    ) { }
}

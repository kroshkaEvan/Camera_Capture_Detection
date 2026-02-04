//
//  Entity.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 30.01.24.
//

import Foundation
import UIKit

enum Screen: Hashable {
    case faceRecognition(FaceRecognitionViewModel)
    case walletsPreFace
    case encrypting
    case alert(AlertModel)
    
    static func == (lhs: Screen, rhs: Screen) -> Bool {
        switch (lhs, rhs) {
        case (.faceRecognition, .faceRecognition):
            return true
        case (.walletsPreFace, .walletsPreFace):
            return true
        case (.encrypting, .encrypting):
            return true
        case (.alert(let lhsModel), .alert(let rhsModel)):
            return lhsModel.id == rhsModel.id
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .faceRecognition:
            hasher.combine(0)
        case .walletsPreFace:
            hasher.combine(1)
        case .encrypting:
            hasher.combine(2)
        case .alert(let model):
            hasher.combine(3)
            hasher.combine(model.id)
        }
    }
}

struct AlertModel: Hashable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButtonTitle: String
    let primaryAction: () -> Void
    
    static func == (lhs: AlertModel, rhs: AlertModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ViewState {
    case empty
    case loading
    case failed(Error)
    case dismiss
    case showSnackAlert(Bool)
}

enum CameraViewModelAction {
    case windowSizeDetected(CGRect)
    case noFaceDetected
    case faceObservationDetected(FaceGeometryModel)
    case faceQualityObservationDetected(FaceQualityModel)
    case takePhoto
    case retakePhoto
    case sendSelfiePhoto(UIImage)
}

enum FaceState {
    case faceOnCentre
    case faceUp
    case faceDown
    case faceLeft
    case faceRight
    case successCompleted
}

enum FaceVerificationStage {
    case notStarted
    case inProgress(sequence: [FaceState])
    case success
    case failed
}

extension FaceVerificationStage: CustomStringConvertible {
    var description: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress(let sequence):
            return "In Progress (\(sequence.count) steps)"
        case .success:
            return "Success"
        case .failed:
            return "Failed"
        }
    }
}

enum FaceBoundsState {
    case unknown
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case detectedFaceOffCentre
    case detectedFaceAppropriateSizeAndPosition
}

enum FaceDetectedState {
    case faceDetected
    case noFaceDetected
    case faceDetectionErrored
}

struct FaceGeometryModel {
    let boundingBox: CGRect
    let roll: NSNumber
    let pitch: NSNumber
    let yaw: NSNumber
}

struct FaceQualityModel {
    let quality: Float
}

enum FaceObservation<T> {
    case faceNotFound
    case errored(Error)
    case faceFound(T)
}

enum FaceVerificationError: LocalizedError {
    case fileManagerError
    case imageSaveFailed
    case directoryCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .fileManagerError:
            return "File manager error occurred"
        case .imageSaveFailed:
            return "Failed to save image"
        case .directoryCreationFailed:
            return "Failed to create directory"
        }
    }
}

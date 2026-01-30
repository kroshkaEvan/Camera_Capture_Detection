//
//  WalletsPreFaceViewModel.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 30.01.24.
//

import Foundation
import AVFoundation
import UIKit

protocol WalletsPreFaceViewModelProtocol: ObservableObject, Identifiable {
    var coordinator: AppCoordinator? { get set }
    func openFaceRecognition()
}

final class WalletsPreFaceViewModel: ObservableObject, WalletsPreFaceViewModelProtocol {
    weak var coordinator: AppCoordinator?
    
    func openFaceRecognition() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            requestCameraAccess()
        case .authorized:
            navigateToFaceRecognition()
        default:
            showCameraPermissionAlert()
        }
    }
}

private extension WalletsPreFaceViewModel {
    func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.navigateToFaceRecognition()
                } else {
                    self?.showCameraPermissionAlert()
                }
            }
        }
    }
    
    func navigateToFaceRecognition() {
        coordinator?.push(.encrypting)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.coordinator?.pop()
            AppCoordinator.shared.navigateToFaceRecognition()
        }
    }
    
    func showCameraPermissionAlert() {
        let alertModel = AlertModel(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to use face verification.",
            primaryButtonTitle: "Open Settings"
        ) {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        
        coordinator?.push(.alert(alertModel))
    }
}

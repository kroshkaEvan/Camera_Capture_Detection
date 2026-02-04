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

final class WalletsPreFaceViewModel: WalletsPreFaceViewModelProtocol {
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
            Task { @MainActor in
                granted
                ? self?.navigateToFaceRecognition()
                : self?.showCameraPermissionAlert()
            }
        }
    }
    
    func navigateToFaceRecognition() {
        coordinator?.showEncryptingOverlay()
        
        Task {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                self.coordinator?.hideOverlay()
                AppCoordinator.shared.navigateToFaceRecognition()
            }
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

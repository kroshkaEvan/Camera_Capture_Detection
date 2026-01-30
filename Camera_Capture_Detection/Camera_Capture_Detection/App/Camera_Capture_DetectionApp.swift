//
//  Camera_Capture_DetectionApp.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 28.01.24.
//

import SwiftUI

@main
struct CameraApp: App {
    @StateObject private var coordinator = AppCoordinator.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.navigationPath) {
                WalletsPreFaceView(viewModel: WalletsPreFaceViewModel())
                    .navigationDestination(for: Screen.self) { screen in
                        switch screen {
                        case .faceRecognition(let viewModel):
                            FaceRecognitionView(viewModel: viewModel)
                        case .walletsPreFace:
                            WalletsPreFaceView(viewModel: WalletsPreFaceViewModel())
                        case .encrypting:
                            EncryptingFileView()
                        case .alert(let alertModel):
                            AppAlertView(
                                title: alertModel.title,
                                message: alertModel.message,
                                primaryButtonTitle: alertModel.primaryButtonTitle,
                                primaryAction: alertModel.primaryAction
                            )
                        }
                    }
            }
            .environmentObject(coordinator)
        }
    }
}

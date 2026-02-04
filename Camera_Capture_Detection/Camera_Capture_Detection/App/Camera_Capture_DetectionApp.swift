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
            ZStack {
                NavigationStack(path: $coordinator.navigationPath) {
                    WalletsPreFaceView(viewModel: WalletsPreFaceViewModel())
                        .navigationDestination(for: Screen.self) { screen in
                            Group {
                                switch screen {
                                case .faceRecognition(let viewModel):
                                    FaceRecognitionView(viewModel: viewModel)
                                case .walletsPreFace:
                                    WalletsPreFaceView(viewModel: WalletsPreFaceViewModel())
                                case .alert(let alertModel):
                                    AppAlertView(
                                        title: alertModel.title,
                                        message: alertModel.message,
                                        primaryButtonTitle: alertModel.primaryButtonTitle,
                                        primaryAction: alertModel.primaryAction
                                    )
                                default:
                                    EmptyView()
                                }
                            }
                        }
                }
                .environmentObject(coordinator)
                
                if let overlayState = coordinator.overlayState {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    OverlayContainer(state: overlayState)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.overlayState)
        }
    }
}

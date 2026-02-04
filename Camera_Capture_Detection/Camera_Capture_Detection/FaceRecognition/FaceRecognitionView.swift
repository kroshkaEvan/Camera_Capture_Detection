//
//  FaceRecognitionView.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 30.01.24.
//

import SwiftUI

struct FaceRecognitionView<ViewModel>: View where ViewModel: FaceRecognitionViewModelProtocol {
    @ObservedObject
    private var viewModel: ViewModel
    @EnvironmentObject
    private var coordinator: AppCoordinator
    
    init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel())
    }
    
    var body: some View {
        content
            .overlay {
                switch viewModel.state {
                case .failed(let error):
                    AppAlertView(
                        title: "Error",
                        message: error.localizedDescription,
                        primaryButtonTitle: "OK",
                        primaryAction: {
                            viewModel.state = .empty
                            coordinator.pop()
                        }
                    )
                default:
                    EmptyView()
                }
            }
            .onDisappear {
                viewModel.resetModel()
            }
    }
    
    private var content: some View {
        VStack {
            GeometryReader { geo in
                ZStack {
                    FaceCameraView(model: viewModel)
                    
                    LayoutGuideView(
                        layoutGuideFrame: viewModel.faceLayoutGuideFrame,
                        hasDetectedValidFace: viewModel.hasDetectedValidFace,
                        progress: viewModel.progressPercentage
                    )
                    
                    FaceOverlayView(viewModel: viewModel)
                }
                .ignoresSafeArea()
                .onAppear {
                    viewModel.perform(action: .windowSizeDetected(geo.frame(in: .local)))
                    viewModel.generateSequence()
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onDisappear {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
    }
}

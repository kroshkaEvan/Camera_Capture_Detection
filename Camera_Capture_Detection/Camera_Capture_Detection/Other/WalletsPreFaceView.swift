//
//  WalletsPreFaceView.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 30.01.24.
//

import SwiftUI

struct WalletsPreFaceView<ViewModel>: View where ViewModel: WalletsPreFaceViewModelProtocol {
    @ObservedObject
    private var viewModel: ViewModel
    @EnvironmentObject
    private var coordinator: AppCoordinator
    
    init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel())
    }
    
    var body: some View {
        content
            .background(Color.cyan)
            .onAppear {
                viewModel.coordinator = coordinator
            }
    }
    
    private var content: some View {
        GeometryReader { geo in
            VStack {
                VStack {
                    AppHeaderView(
                        style: .main,
                        image: Image(systemName: "faceid"),
                        imageBackgroundColor: .mint,
                        titleText: "Face verification",
                        secondaryText: "We use this to verify who you are and that nobody is trying to impersonate you."
                    )
                    .frame(height: geo.size.width * 0.80)
                    
                    VStack {
                        WalletsPreFaceInstructionView()
                            .padding(.bottom, 10)
                        
                        AppButton(title: "Let's get started", style: .primary) {
                            viewModel.openFaceRecognition()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WalletsPreFaceInstructionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Instructions:")
                .font(.headline)
                .foregroundColor(.black)
            
            instructionRow("1.", "Look straight at the camera")
            instructionRow("2.", "Keep your face within the frame")
            instructionRow("3.", "Follow the on-screen instructions")
            instructionRow("4.", "Hold still while photos are taken")
            instructionRow("5.", "Turn head as instructed")
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 3)
    }
    
    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(text)
                .foregroundColor(.black)
            Spacer()
        }
    }
}

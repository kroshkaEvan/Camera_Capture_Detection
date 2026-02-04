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
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1),
                        Color.cyan.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .onAppear {
                viewModel.coordinator = coordinator
            }
    }
    
    private var content: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    AppHeaderView(
                        style: .main,
                        image: Image(systemName: "faceid"),
                        titleText: "Face Verification",
                        secondaryText: "We use facial recognition to verify your identity and ensure security. Follow the on-screen instructions to complete the process."
                    )
                    .frame(height: geo.size.width * 0.9)
                    
                    VStack(spacing: 24) {
                        WalletsPreFaceInstructionView()
                            .padding(.horizontal)
                        
                        AppButton(title: "Let's get started", style: .primary) {
                            viewModel.openFaceRecognition()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WalletsPreFaceInstructionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            ForEach(instructions, id: \.number) { instruction in
                instructionRow(instruction)
            }
        }
        .padding(24)
        .background(
            VisualEffectView(style: .systemThinMaterial)
                .cornerRadius(16)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private let instructions = [
        (number: "1", text: "Look straight at the camera"),
        (number: "2", text: "Keep your face within the frame"),
        (number: "3", text: "Follow the on-screen instructions"),
        (number: "4", text: "Hold still while photos are taken"),
        (number: "5", text: "Turn head as instructed"),
        (number: "6", text: "Complete all poses to finish")
    ]
    
    private func instructionRow(_ instruction: (number: String, text: String)) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(instruction.number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
            
            Text(instruction.text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

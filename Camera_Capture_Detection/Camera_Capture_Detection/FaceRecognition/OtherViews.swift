//
//  OtherViews.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 10.01.24.
//

import SwiftUI

// MARK: - FaceOverlayView

struct FaceOverlayView<ViewModel>: View where ViewModel: FaceRecognitionViewModelProtocol {
    @ObservedObject
    private var viewModel: ViewModel
    @State
    private var showDebugInfo = false
    
    init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel())
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Spacer()
                    
                    Group {
                        if case .successCompleted = viewModel.stateFace {
                            successView
                        } else if let sequenceInfo = getSequenceInfo() {
                            sequenceInstructionView(sequenceInfo)
                        } else {
                            defaultInstructionView
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 100)
                }
                
                VStack {
                    if viewModel.faceDetectedState == .noFaceDetected {
                        Text("No face detected")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding(.top, 50)
                
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showDebugInfo.toggle()
                            }
                        } label: {
                            Image(systemName: showDebugInfo ? "xmark.circle.fill" : "ladybug.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(
                                    VisualEffectView(style: .systemThinMaterialDark)
                                        .clipShape(Circle())
                                )
                                .shadow(color: .black.opacity(0.3), radius: 5)
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                
                if showDebugInfo {
                    DebugView(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    private var successView: some View {
        VStack(spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Verification Success!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("All poses captured successfully")
                .font(.title3)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            VisualEffectView(style: .systemUltraThinMaterialDark)
                .cornerRadius(15)
        )
    }
    
    private var defaultInstructionView: some View {
        Group {
            switch viewModel.stateFace {
            case .faceOnCentre:
                Text("Look straight at the camera")
            case .faceLeft:
                Text("Turn your head to the LEFT")
            case .faceRight:
                Text("Turn your head to the RIGHT")
            case .faceUp:
                Text("Look UP")
            case .faceDown:
                Text("Look DOWN")
            case .successCompleted:
                Text("Verification complete!")
            }
        }
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .padding()
        .background(
            VisualEffectView(style: .systemUltraThinMaterialDark)
                .cornerRadius(10)
        )
    }
    
    private func sequenceInstructionView(
        _ info: (
            current: Int,
            total: Int,
            currentPose: String
        )
    ) -> some View {
        VStack(spacing: 10) {
            Text("Step \(info.current)/\(info.total)")
                .font(.headline)
                .foregroundColor(.yellow)
                .fontWeight(.bold)
            
            Text("\(info.currentPose)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ProgressView(value: Double(info.current), total: Double(info.total))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(width: 200)
            
            if viewModel.hasDetectedValidFace && viewModel.progressPercentage > 0 {
                Text("\(Int(viewModel.progressPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(
            VisualEffectView(style: .systemUltraThinMaterialDark)
                .cornerRadius(15)
        )
    }
    
    private func getSequenceInfo() -> (
        current: Int,
        total: Int,
        currentPose: String
    )? {
        let vm = viewModel
        
        if case .inProgress(let sequence) = vm.verificationStage {
            guard vm.currentSequenceIndex < sequence.count else {
                return nil
            }
            
            let currentStep = vm.currentSequenceIndex + 1
            let totalSteps = sequence.count
            let currentPose: String
            let currentState = sequence[vm.currentSequenceIndex]
            
            switch currentState {
            case .faceOnCentre:
                currentPose = "Look STRAIGHT at camera"
            case .faceLeft:
                currentPose = "Turn head to the LEFT"
            case .faceRight:
                currentPose = "Turn head to the RIGHT"
            case .faceUp:
                currentPose = "Look UP"
            case .faceDown:
                currentPose = "Look DOWN"
            case .successCompleted:
                currentPose = "Verification complete!"
            }
            
            return (currentStep, totalSteps, currentPose)
        }
        
        return nil
    }
}

// MARK: - DebugView

struct DebugView<ViewModel>: View where ViewModel: FaceRecognitionViewModelProtocol {
    @ObservedObject
    private var viewModel: ViewModel
    
    init(viewModel: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debug Information")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    debugSection("Current State") {
                        debugRow("Pose", viewModel.debugInfo.currentPose)
                        debugRow("Sequence", viewModel.debugInfo.sequenceProgress)
                        debugRow("Stage", "\(viewModel.verificationStageDescription)")
                    }
                    debugSection("Face Data") {
                        if let roll = viewModel.debugInfo.roll {
                            debugRow("Roll", String(format: "%.2f rad", roll))
                        }
                        if let pitch = viewModel.debugInfo.pitch {
                            debugRow("Pitch", String(format: "%.2f rad", pitch))
                        }
                        if let yaw = viewModel.debugInfo.yaw {
                            debugRow("Yaw", String(format: "%.2f rad", yaw))
                        }
                        if let quality = viewModel.debugInfo.quality {
                            debugRow("Quality", String(format: "%.2f", quality))
                        }
                    }
                    debugSection("Validations") {
                        debugRow("Roll OK", viewModel.isAcceptableRoll ? "✓" : "✗", color: viewModel.isAcceptableRoll ? .green : .red)
                        debugRow("Pitch OK", viewModel.isAcceptablePitch ? "✓" : "✗", color: viewModel.isAcceptablePitch ? .green : .red)
                        debugRow("Yaw OK", viewModel.isAcceptableYaw ? "✓" : "✗", color: viewModel.isAcceptableYaw ? .green : .red)
                        debugRow("Quality OK", viewModel.isAcceptableQuality ? "✓" : "✗", color: viewModel.isAcceptableQuality ? .green : .red)
                        debugRow("Bounds", "\(viewModel.debugInfo.boundsState)")
                    }
                    
                    debugSection("Position & Timer") {
                        if let position = viewModel.debugInfo.facePosition {
                            debugRow("Face X", String(format: "%.0f", position.x))
                            debugRow("Face Y", String(format: "%.0f", position.y))
                        }
                        debugRow("Timer Progress", "\(Int(viewModel.debugInfo.timerProgress * 100))%")
                        debugRow("Valid Face", viewModel.hasDetectedValidFace ? "YES" : "NO", color: viewModel.hasDetectedValidFace ? .green : .red)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 400)
        }
        .padding(16)
        .background(
            VisualEffectView(style: .systemUltraThinMaterialDark)
                .cornerRadius(16)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.top, 100)
    }
    
    private func debugSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 4)
            
            content()
        }
    }
    
    private func debugRow(_ title: String, _ value: String, color: Color = .white) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// MARK: - LayoutGuideView

struct LayoutGuideView: View {
    let layoutGuideFrame: CGRect
    let hasDetectedValidFace: Bool
    let progress: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    path.addRect(CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height))
                    path.addRoundedRect(in: layoutGuideFrame, cornerSize: CGSize(width: 20, height: 20))
                }
                .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        hasDetectedValidFace ? Color.green : Color.white,
                        lineWidth: 4
                    )
                    .frame(
                        width: layoutGuideFrame.width,
                        height: layoutGuideFrame.height
                    )
                    .position(
                        x: layoutGuideFrame.midX,
                        y: layoutGuideFrame.midY
                    )
                
                if hasDetectedValidFace && progress > 0 {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(Color.green, lineWidth: 4)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((1 - progress) * 100))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .position(x: layoutGuideFrame.midX, y: layoutGuideFrame.minY - 50)
                }
            }
        }
    }
    
    private func cornerIndicator(at index: Int) -> some View {
        let cornerPoints = [
            CGPoint(x: layoutGuideFrame.minX, y: layoutGuideFrame.minY),
            CGPoint(x: layoutGuideFrame.maxX, y: layoutGuideFrame.minY),
            CGPoint(x: layoutGuideFrame.maxX, y: layoutGuideFrame.maxY),
            CGPoint(x: layoutGuideFrame.minX, y: layoutGuideFrame.maxY)
        ]
        
        let cornerSize: CGFloat = 30
        
        return Rectangle()
            .fill(Color.clear)
            .frame(width: cornerSize, height: 4)
            .overlay(
                Rectangle()
                    .fill(hasDetectedValidFace ? Color.green : Color.white)
                    .frame(width: cornerSize, height: 4)
            )
            .rotationEffect(.degrees(Double(index) * 90))
            .position(cornerPoints[index])
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 4, height: cornerSize)
                    .overlay(
                        Rectangle()
                            .fill(hasDetectedValidFace ? Color.green : Color.white)
                            .frame(width: 4, height: cornerSize)
                    )
                    .rotationEffect(.degrees(Double(index) * 90))
                    .position(cornerPoints[index])
            )
    }
}

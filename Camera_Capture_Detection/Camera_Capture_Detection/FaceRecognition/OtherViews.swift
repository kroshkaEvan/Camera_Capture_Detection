//
//  OtherViews.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 10.01.24.
//

import SwiftUI

// MARK: - FaceOverlayView

struct FaceOverlayView<ViewModel>: View where ViewModel: FaceRecognitionViewModelProtocol {
    @ObservedObject private var viewModel: ViewModel
    
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
                    
                    Spacer()
                        .frame(height: 100)
                }
                
                VStack {
                    if viewModel.faceDetectedState == .noFaceDetected {
                        Text("No face detected")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding(.top, 50)
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
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
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
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
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
            
            if viewModel.hasDetectedValidFace && viewModel.timeLeft > 0 {
                Text("\(min(100, viewModel.timeLeft * 100 / 30))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
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
    @State
    private var showDebugInfo = false

    init(model: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: model)
    }

    var body: some View {
        VStack {
            Spacer()

            if showDebugInfo {
                debugInfoView
                    .transition(.opacity)
            }

            Button {
                withAnimation {
                    showDebugInfo.toggle()
                }
            } label: {
                Image(systemName: "ladybug.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.bottom, 30)
        }
    }

    private var debugInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Information")
                .font(.headline)
                .foregroundColor(.white)

            debugRow("Face State", "\(viewModel.stateFace)")
            debugRow("Roll", viewModel.isAcceptableRoll ? "✓" : "✗")
            debugRow("Pitch", viewModel.isAcceptablePitch ? "✓" : "✗")
            debugRow("Yaw", viewModel.isAcceptableYaw ? "✓" : "✗")
            debugRow("Bounds", "\(viewModel.isAcceptableBounds)")
            debugRow("Quality", viewModel.isAcceptableQuality ? "✓" : "✗")
            debugRow("Valid Face", viewModel.hasDetectedValidFace ? "YES" : "NO")
            debugRow("Timer", "\(viewModel.timeLeft)")
        }
        .padding()
        .background(Color.black.opacity(0.75))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func debugRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

// MARK: - LayoutGuideView

struct LayoutGuideView: View {
    let layoutGuideFrame: CGRect
    let hasDetectedValidFace: Bool
    let count: Int
    
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
                
                if hasDetectedValidFace && count > 0 {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(count) / 100)
                            .stroke(Color.green, lineWidth: 4)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(100 - count)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .position(x: layoutGuideFrame.midX, y: layoutGuideFrame.minY - 50)
                }
                
                ForEach(0..<4) { index in
                    cornerIndicator(at: index)
                }
                
                Path { path in
                    path.move(to: CGPoint(x: layoutGuideFrame.minX, y: layoutGuideFrame.midY))
                    path.addLine(to: CGPoint(x: layoutGuideFrame.maxX, y: layoutGuideFrame.midY))
                    path.move(to: CGPoint(x: layoutGuideFrame.midX, y: layoutGuideFrame.minY))
                    path.addLine(to: CGPoint(x: layoutGuideFrame.midX, y: layoutGuideFrame.maxY))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .frame(
                    width: layoutGuideFrame.width,
                    height: layoutGuideFrame.height
                )
                .position(
                    x: layoutGuideFrame.midX,
                    y: layoutGuideFrame.midY
                )
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

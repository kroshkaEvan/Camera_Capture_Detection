//
//  UIComponents.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 28.01.24.
//

import SwiftUI
import AVFoundation
import Vision
import Combine

struct OverlayContainer: View {
    let state: OverlayState
    
    var body: some View {
        VStack(spacing: 20) {
            switch state {
            case .loading:
                LoadingOverlayView()
            case .progress(let progress, let message):
                ProgressOverlayView(progress: progress, message: message)
            case .success(let title, let message):
                SuccessOverlayView(title: title, message: message)
            case .error(let title, let message):
                ErrorOverlayView(title: title, message: message)
            }
        }
        .padding(30)
        .background(
            VisualEffectView(style: .systemUltraThinMaterialDark)
                .cornerRadius(20)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 40)
    }
}

struct LoadingOverlayView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Please wait...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

struct ProgressOverlayView: View {
    let progress: Float
    let message: String?
    
    var body: some View {
        VStack(spacing: 20) {
            CircularProgressView(progress: progress)
            
            VStack(spacing: 8) {
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let message = message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct SuccessOverlayView: View {
    let title: String
    let message: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let message = message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct ErrorOverlayView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Float
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 80)
    }
}

struct AppAlertView: View {
    let title: String
    let message: String
    let primaryButtonTitle: String
    let primaryAction: () -> Void
    @EnvironmentObject
    private var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            AppButton(title: primaryButtonTitle, style: .primary) {
                primaryAction()
                coordinator.pop()
            }
        }
        .padding(24)
        .background(
            VisualEffectView(style: .systemThinMaterial)
                .cornerRadius(16)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 32)
        .navigationBarBackButtonHidden()
    }
}

enum AppButtonStyle {
    case primary
    case secondary
    case disabled
    
    var foregroundColor: Color {
        switch self {
        case .primary: .white
        case .secondary: .primary
        case .disabled: .gray
        }
    }
    
    var backgroundColor: some View {
        switch self {
        case .primary:
            return AnyView(Color.blue)
        case .secondary:
            return AnyView(VisualEffectView(style: .systemThinMaterial))
        case .disabled:
            return AnyView(Color.gray.opacity(0.3))
        }
    }
}

struct AppButton: View {
    let title: String
    let style: AppButtonStyle
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(style.backgroundColor)
                .cornerRadius(12)
        }
        .disabled(style == .disabled)
        .opacity(style == .disabled ? 0.6 : 1.0)
    }
}

enum HeaderStyle {
    case top
    case middle
    case main
}

struct AppHeaderView: View {
    let style: HeaderStyle
    let image: Image
    let titleText: String?
    let secondaryText: String?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                if style == .top || style == .main {
                    imageView(size: geometry.size.width * 0.7)
                }
                
                VStack(spacing: 16) {
                    if let titleText = titleText {
                        Text(titleText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                    }
                    
                    if style == .middle {
                        imageView(size: geometry.size.width)
                    }
                    
                    if let secondaryText = secondaryText {
                        Text(secondaryText)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    private func imageView(size: CGFloat) -> some View {
        ZStack {
            VisualEffectView(style: .systemThinMaterial)
                .frame(width: size / 2, height: size / 2)
                .cornerRadius(size / 4)
            
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size / 3.5, height: size / 3.5)
                .foregroundColor(.blue)
        }
    }
}

struct VisualEffectView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

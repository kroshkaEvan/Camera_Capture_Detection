//
//  UICopmonents.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 28.01.24.
//

import SwiftUI
import AVFoundation
import Vision
import Combine
import MetalKit
import CoreImage

struct EncryptingFileView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Encrypting file to the blockchain")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
            
            Text("Sit tight, this should only take a few seconds.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .navigationBarBackButtonHidden()
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
            Text(title)
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
            
            AppButton(title: primaryButtonTitle, style: .primary) {
                primaryAction()
                coordinator.pop()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
        .navigationBarBackButtonHidden()
    }
}

enum AppButtonStyle {
    case primary
    case secondary
    case disabled
}

struct AppButton: View {
    let title: String
    let style: AppButtonStyle
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .cornerRadius(25)
        }
        .disabled(style == .disabled)
        .opacity(style == .disabled ? 0.6 : 1.0)
    }
}

extension AppButton {
    private var foregroundColor: Color {
        switch style {
        case .primary: .white
        case .secondary: .black
        case .disabled: .gray
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: .black
        case .secondary: .clear
        case .disabled: .gray.opacity(0.3)
        }
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
    let imageBackgroundColor: Color
    let titleText: String?
    let secondaryText: String?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                if style == .top || style == .main {
                    imageView(size: geometry.size.width * 0.8)
                }
                
                VStack(spacing: 10) {
                    if let titleText = titleText {
                        Text(titleText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    
                    if style == .middle {
                        imageView(size: geometry.size.width)
                    }
                    
                    if let secondaryText = secondaryText {
                        Text(secondaryText)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
    }
}

private extension AppHeaderView {
    func imageView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(imageBackgroundColor)
                .frame(width: size / 2.5, height: size / 2.5)
            
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size / 3.5, height: size / 3.5)
                .foregroundColor(.white)
        }
    }
}

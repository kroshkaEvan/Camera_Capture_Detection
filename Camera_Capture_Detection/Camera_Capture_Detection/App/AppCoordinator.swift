//
//  AppCoordinator.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 30.01.24.
//

import Foundation
import SwiftUI

// MARK: - Navigation

protocol CoordinatorProtocol: AnyObject, ObservableObject {
    var navigationPath: [Screen] { get set }
    var overlayState: OverlayState? { get set }
    func push(_ screen: Screen)
    func pop()
    func showOverlay(_ state: OverlayState)
    func hideOverlay()
}

enum OverlayState: Hashable {
    case loading
    case progress(Float, String?)
    case success(String, String?)
    case error(String, String)
    
    static func == (lhs: OverlayState, rhs: OverlayState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.progress(let lhsProgress, let lhsMessage), .progress(let rhsProgress, let rhsMessage)):
            return lhsProgress == rhsProgress && lhsMessage == rhsMessage
        case (.success(let lhsTitle, let lhsMessage), .success(let rhsTitle, let rhsMessage)):
            return lhsTitle == rhsTitle && lhsMessage == rhsMessage
        case (.error(let lhsTitle, let lhsMessage), .error(let rhsTitle, let rhsMessage)):
            return lhsTitle == rhsTitle && lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .loading:
            hasher.combine(0)
        case .progress(let progress, let message):
            hasher.combine(1)
            hasher.combine(progress)
            hasher.combine(message)
        case .success(let title, let message):
            hasher.combine(2)
            hasher.combine(title)
            hasher.combine(message)
        case .error(let title, let message):
            hasher.combine(3)
            hasher.combine(title)
            hasher.combine(message)
        }
    }
}

final class AppCoordinator: CoordinatorProtocol {
    @Published
    var navigationPath: [Screen] = []
    @Published
    var overlayState: OverlayState?
    
    static let shared = AppCoordinator()
    
    private init() {}
    
    func push(_ screen: Screen) {
        Task { @MainActor in
            self.navigationPath.append(screen)
        }
    }
    
    func pop() {
        Task { @MainActor in
            guard !self.navigationPath.isEmpty else { return }
            self.navigationPath.removeLast()
        }
    }
    
    func navigateToFaceRecognition() {
        let viewModel = FaceRecognitionViewModel()
        viewModel.coordinator = self
        push(.faceRecognition(viewModel))
    }
    
    func showOverlay(_ state: OverlayState) {
        Task { @MainActor in
            self.overlayState = state
        }
    }
    
    func hideOverlay() {
        Task { @MainActor in
            self.overlayState = nil
        }
    }
    
    func showEncryptingOverlay() {
        showOverlay(.progress(0.0, "Preparing face verification..."))
    }
}

//
//  AppCoordinator.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 30.01.24.
//

import Foundation

// MARK: - Navigation

protocol CoordinatorProtocol: AnyObject, ObservableObject {
    var navigationPath: [Screen] { get set }
    func push(_ screen: Screen)
    func pop()
}

final class AppCoordinator: CoordinatorProtocol {
    @Published var navigationPath: [Screen] = []
    
    static let shared = AppCoordinator()
    
    private init() {}
    
    func push(_ screen: Screen) {
        DispatchQueue.main.async {
            self.navigationPath.append(screen)
        }
    }
    
    func pop() {
        DispatchQueue.main.async {
            guard !self.navigationPath.isEmpty else { return }
            self.navigationPath.removeLast()
        }
    }
    
    func navigateToFaceRecognition() {
        let viewModel = FaceRecognitionViewModel()
        viewModel.coordinator = self
        push(.faceRecognition(viewModel))
    }
}

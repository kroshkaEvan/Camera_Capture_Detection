//
//  FaceRecognitionViewModel.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 10.01.24.
//

import UIKit
import Combine
import SwiftUI
import AudioToolbox

protocol FaceRecognitionViewModelProtocol: ObservableObject, Identifiable {
    var coordinator: AppCoordinator? { get set }
    func perform(action: CameraViewModelAction)
    func resetModel()
    func generateSequence()
    var state: ViewState { get set }
    var hasDetectedValidFace: Bool { get }
    var faceLayoutGuideFrame: CGRect { get }
    var currentSequenceIndex: Int { get }
    var progressPercentage: Float { get }
    var timeLeft: Int { get }
    var stateFace: FaceState { get }
    var isAcceptableRoll: Bool { get }
    var isAcceptablePitch: Bool { get }
    var isAcceptableYaw: Bool { get }
    var verificationStageDescription: String { get }
    var rollValue: Double? { get }
    var pitchValue: Double? { get }
    var yawValue: Double? { get }
    var isAcceptableBounds: FaceBoundsState { get }
    var isAcceptableQuality: Bool { get }
    var qualityValue: Float? { get }
    var verificationStage: FaceVerificationStage { get }
    var faceDetectedState: FaceDetectedState { get }
    var faceGeometryState: FaceObservation<FaceGeometryModel> { get }
    var faceQualityState: FaceObservation<FaceQualityModel> { get }
    var selfiePhoto: UIImage? { get }
    var debugInfo: DebugInfo { get }
}

struct DebugInfo {
    let roll: Double?
    let pitch: Double?
    let yaw: Double?
    let quality: Float?
    let boundsState: FaceBoundsState
    let facePosition: CGPoint?
    let timerProgress: Float
    let currentPose: String
    let sequenceProgress: String
}

final class FaceRecognitionViewModel: FaceRecognitionViewModelProtocol {
    
    // MARK: - Published
    
    @Published private(set) var hasDetectedValidFace = false
    @Published private(set) var stateFace: FaceState = .faceOnCentre
    @Published private(set) var timeLeft = 0
    @Published private(set) var progressPercentage: Float = 0.0
    @Published var state: ViewState = .empty
    @Published private(set) var faceDetectedState: FaceDetectedState = .noFaceDetected
    @Published private(set) var faceGeometryState: FaceObservation<FaceGeometryModel> = .faceNotFound
    @Published private(set) var faceQualityState: FaceObservation<FaceQualityModel> = .faceNotFound
    @Published private(set) var selfiePhoto: UIImage?
    @Published private(set) var isAcceptableRoll = false
    @Published private(set) var isAcceptablePitch = false
    @Published private(set) var isAcceptableYaw = false
    @Published private(set) var rollValue: Double?
    @Published private(set) var pitchValue: Double?
    @Published private(set) var yawValue: Double?
    @Published private(set) var isAcceptableBounds: FaceBoundsState = .unknown
    @Published private(set) var isAcceptableQuality = false
    @Published private(set) var qualityValue: Float?
    @Published private(set) var currentSequenceIndex = 0
    @Published private(set) var verificationStage: FaceVerificationStage = .notStarted
    @Published private(set) var faceSequence: [FaceState] = []
    @Published private(set) var debugInfo: DebugInfo = .init(
        roll: nil,
        pitch: nil,
        yaw: nil,
        quality: nil,
        boundsState: .unknown,
        facePosition: nil,
        timerProgress: 0,
        currentPose: "Not started",
        sequenceProgress: "0/0"
    )
    
    @Published private(set) var faceLayoutGuideFrame: CGRect = {
        let screen = UIScreen.main.bounds
        return CGRect(
            x: screen.width * 0.1,
            y: screen.height * 0.25,
            width: screen.width * 0.8,
            height: screen.height * 0.5
        )
    }()
    
    // MARK: - Dependencies
    
    weak var coordinator: AppCoordinator?
    private let fileManagerService: FileManagerServiceProtocol
    private var timer: AnyCancellable?
    private var isTimerRunning = false
    private let timerDuration: TimeInterval = 3.0
    private let timerInterval: TimeInterval = 0.1
    private var timerStartTime: Date?
    private var stopTakePhoto = false
    private var savedSelfies: [FaceState: URL] = [:]
    
    let shutterReleased = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    var verificationStageDescription: String {
        switch verificationStage {
        case .notStarted:
            return "Not Started"
        case .inProgress(let sequence):
            return "In Progress (\(currentSequenceIndex + 1)/\(sequence.count))"
        case .success:
            return "Success"
        case .failed:
            return "Failed"
        }
    }
    
    // MARK: - Init
    
    init(fileManagerService: FileManagerServiceProtocol = FileManagerService.shared) {
        self.fileManagerService = fileManagerService
        bindShutter()
    }
    
    // MARK: - Public API
    
    func perform(action: CameraViewModelAction) {
        switch action {
        case .windowSizeDetected(let rect):
            updateLayout(rect)
        case .noFaceDetected:
            resetFaceDetection()
        case .faceObservationDetected(let geometry):
            updateGeometry(geometry)
        case .faceQualityObservationDetected(let quality):
            updateQuality(quality)
        case .sendSelfiePhoto(let image):
            savePhoto(image)
        case .takePhoto:
            shutterReleased.send()
        default:
            break
        }
    }
    
    func resetModel() {
        stopTakePhoto = true
        stopTimer()
        cancellables.removeAll()
        resetFaceDetection()
        resetSequence()
    }
    
    func generateSequence() {
        faceSequence = [
            .faceOnCentre,
            .faceUp,
            .faceLeft,
            .faceDown,
            .faceRight,
            .faceOnCentre
        ]
        verificationStage = .inProgress(sequence: faceSequence)
        currentSequenceIndex = 0
        stateFace = faceSequence[0]
        updateDebugInfo()
    }
}

private extension FaceRecognitionViewModel {
    func bindShutter() {
        shutterReleased
            .sink { [weak self] in
                self?.takePhoto()
            }
            .store(in: &cancellables)
    }
    
    func updateLayout(_ rect: CGRect) {
        faceLayoutGuideFrame = CGRect(
            x: rect.midX - faceLayoutGuideFrame.width / 2,
            y: rect.midY - faceLayoutGuideFrame.height / 2,
            width: faceLayoutGuideFrame.width,
            height: faceLayoutGuideFrame.height
        )
    }
    
    func resetFaceDetection() {
        hasDetectedValidFace = false
        isAcceptableRoll = false
        isAcceptablePitch = false
        isAcceptableYaw = false
        isAcceptableQuality = false
        isAcceptableBounds = .unknown
        rollValue = nil
        pitchValue = nil
        yawValue = nil
        qualityValue = nil
        
        faceDetectedState = .noFaceDetected
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound
        
        stopTimer()
        updateDebugInfo()
    }
    
    func updateGeometry(_ model: FaceGeometryModel) {
        faceDetectedState = .faceDetected
        faceGeometryState = .faceFound(model)
        
        let boundingBox = model.boundingBox
        let roll = model.roll.doubleValue
        let pitch = model.pitch.doubleValue
        let yaw = model.yaw.doubleValue
        
        rollValue = roll
        pitchValue = pitch
        yawValue = yaw
        
        updateAcceptableBounds(using: boundingBox)
        updateAcceptableRollPitchYaw(using: roll, pitch: pitch, yaw: yaw)
        
        validateFace()
        updateDebugInfo()
    }
    
    func updateQuality(_ model: FaceQualityModel) {
        faceDetectedState = .faceDetected
        faceQualityState = .faceFound(model)
        qualityValue = model.quality
        isAcceptableQuality = model.quality >= 0.2
        validateFace()
        updateDebugInfo()
    }
    
    func validateFace() {
        let valid =
        isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition &&
        isAcceptableRoll &&
        isAcceptablePitch &&
        isAcceptableYaw &&
        isAcceptableQuality
        
        hasDetectedValidFace = valid
        valid ? startTimer() : stopTimer()
    }
    
    func updateAcceptableBounds(using boundingBox: CGRect) {
        var valueFaceLarge: CGFloat = 0.95
        var valueFaceSmall: CGFloat = 1.5
        
        if stateFace != .faceOnCentre {
            valueFaceLarge = 1.4
            valueFaceSmall = 2.0
        }
        
        if boundingBox.width > valueFaceLarge * faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooLarge
            return
        }
        
        if boundingBox.width * valueFaceSmall < faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooSmall
            return
        }
        
        if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 75 ||
            abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 75 {
            isAcceptableBounds = .detectedFaceOffCentre
            return
        }
        
        isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
    }
    
    func updateAcceptableRollPitchYaw(
        using roll: Double,
        pitch: Double,
        yaw: Double
    ) {
        switch stateFace {
        case .faceOnCentre:
            isAcceptableRoll = roll > 1.0 && roll < 3.0
            isAcceptablePitch = abs(CGFloat(pitch)) < 0.15
            isAcceptableYaw = abs(CGFloat(yaw)) < 0.15
        case .faceUp:
            isAcceptableRoll = roll > 1.0 && roll < 3.0
            isAcceptablePitch = CGFloat(pitch) < -0.20 && CGFloat(pitch) > -0.80
            isAcceptableYaw = true
        case .faceDown:
            isAcceptableRoll = roll > 1.0 && roll < 3.0
            isAcceptablePitch = CGFloat(pitch) > 0.10 && CGFloat(pitch) < 0.80
            isAcceptableYaw = true
        case .faceLeft:
            isAcceptableRoll = roll > 1.0 && roll < 3.0
            isAcceptablePitch = true
            isAcceptableYaw = CGFloat(yaw) < -0.10
        case .faceRight:
            isAcceptableRoll = roll > 1.0 && roll < 3.0
            isAcceptablePitch = true
            isAcceptableYaw = CGFloat(yaw) > 0.10
        case .successCompleted:
            isAcceptableRoll = true
            isAcceptablePitch = true
            isAcceptableYaw = true
        }
    }
    
    func startTimer() {
        guard !isTimerRunning else { return }
        
        isTimerRunning = true
        timerStartTime = Date()
        
        timer = Timer
            .publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let startTime = self.timerStartTime else { return }
                
                let elapsed = Date().timeIntervalSince(startTime)
                self.progressPercentage = Float(min(elapsed / self.timerDuration, 1.0))
                
                if elapsed >= self.timerDuration {
                    self.finishStep()
                }
                
                self.updateDebugInfo()
            }
    }
    
    func stopTimer() {
        timer?.cancel()
        timer = nil
        isTimerRunning = false
        timerStartTime = nil
        progressPercentage = 0.0
        updateDebugInfo()
    }
    
    func finishStep() {
        stopTimer()
        guard !stopTakePhoto else { return }
        
        AudioServicesPlaySystemSound(SystemSoundID(1108))
        shutterReleased.send()
    }
    
    func takePhoto() {
        debugPrint("📸 takePhoto triggered")
    }
    
    func savePhoto(_ image: UIImage) {
        selfiePhoto = image
        
        guard case .inProgress(let sequence) = verificationStage else { return }
        
        let pose = sequence[currentSequenceIndex]
        
        Task { @MainActor in
            do {
                let url = try await fileManagerService.saveSelfie(image, for: pose)
                savedSelfies[pose] = url
                advanceSequence()
            } catch {
                state = .failed(error)
                showError(error)
            }
        }
    }
    
    func advanceSequence() {
        guard case .inProgress(let sequence) = verificationStage else { return }
        
        let nextIndex = currentSequenceIndex + 1
        
        if nextIndex < sequence.count {
            currentSequenceIndex = nextIndex
            stateFace = sequence[nextIndex]
            progressPercentage = 0.0
            resetFaceDetection()
        } else {
            verificationStage = .success
            stateFace = .successCompleted
            showSuccess()
        }
        
        updateDebugInfo()
    }
    
    func resetSequence() {
        verificationStage = .notStarted
        faceSequence = []
        currentSequenceIndex = 0
        progressPercentage = 0.0
        updateDebugInfo()
    }
    
    func showSuccess() {
        coordinator?.push(.alert(
            AlertModel(
                title: "Success",
                message: "Face verification completed",
                primaryButtonTitle: "OK",
                primaryAction: { [weak self] in
                    self?.coordinator?.pop()
                }
            )
        ))
    }
    
    func showError(_ error: Error) {
        coordinator?.push(.alert(
            AlertModel(
                title: "Error",
                message: error.localizedDescription,
                primaryButtonTitle: "Retry",
                primaryAction: { [weak self] in
                    self?.resetSequence()
                }
            )
        ))
    }
    
    func updateDebugInfo() {
        let facePosition: CGPoint?
        if case .faceFound(let geometry) = faceGeometryState {
            facePosition = geometry.boundingBox.origin
        } else {
            facePosition = nil
        }
        
        let currentPose: String
        switch stateFace {
        case .faceOnCentre: currentPose = "Face On Centre"
        case .faceUp: currentPose = "Face Up"
        case .faceDown: currentPose = "Face Down"
        case .faceLeft: currentPose = "Face Left"
        case .faceRight: currentPose = "Face Right"
        case .successCompleted: currentPose = "Success Completed"
        }
        
        let sequenceProgress = "\(currentSequenceIndex + 1)/\(faceSequence.count)"
        
        debugInfo = DebugInfo(
            roll: rollValue,
            pitch: pitchValue,
            yaw: yawValue,
            quality: qualityValue,
            boundsState: isAcceptableBounds,
            facePosition: facePosition,
            timerProgress: progressPercentage,
            currentPose: currentPose,
            sequenceProgress: sequenceProgress
        )
    }
}

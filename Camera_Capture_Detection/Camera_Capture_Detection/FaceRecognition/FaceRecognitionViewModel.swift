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
    var timeLeft: Int { get }
    var stateFace: FaceState { get }
    var isAcceptableRoll: Bool { get }
    var isAcceptablePitch: Bool { get }
    var isAcceptableYaw: Bool { get }
    var isAcceptableBounds: FaceBoundsState { get }
    var isAcceptableQuality: Bool { get }
    var verificationStage: FaceVerificationStage { get }
    var faceDetectedState: FaceDetectedState { get }
    var faceGeometryState: FaceObservation<FaceGeometryModel> { get }
    var faceQualityState: FaceObservation<FaceQualityModel> { get }
    var selfiePhoto: UIImage? { get }
}

// MARK: - FaceRecognitionViewModel

final class FaceRecognitionViewModel: FaceRecognitionViewModelProtocol {

    // MARK: - Published state

    @Published private(set) var hasDetectedValidFace = false
    @Published private(set) var stateFace: FaceState = .faceOnCentre
    @Published private(set) var timeLeft = 0
    @Published var state: ViewState = .empty
    @Published private(set) var faceDetectedState: FaceDetectedState = .noFaceDetected
    @Published private(set) var faceGeometryState: FaceObservation<FaceGeometryModel> = .faceNotFound
    @Published private(set) var faceQualityState: FaceObservation<FaceQualityModel> = .faceNotFound
    @Published private(set) var selfiePhoto: UIImage?
    @Published private(set) var isAcceptableRoll = false
    @Published private(set) var isAcceptablePitch = false
    @Published private(set) var isAcceptableYaw = false
    @Published private(set) var isAcceptableBounds: FaceBoundsState = .unknown
    @Published private(set) var isAcceptableQuality = false
    @Published private(set) var currentSequenceIndex = 0
    @Published private(set) var verificationStage: FaceVerificationStage = .notStarted
    @Published private(set) var faceSequence: [FaceState] = []

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

    // MARK: - Timer

    private var timer: AnyCancellable?
    private var isTimerRunning = false
    private let timerTicksRequired = 30

    // MARK: - Other

    private var stopTakePhoto = false
    private var savedSelfies: [FaceState: URL] = [:]

    let shutterReleased = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

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

        faceDetectedState = .noFaceDetected
        faceGeometryState = .faceNotFound
        faceQualityState = .faceNotFound

        stopTimer()
    }

    func updateGeometry(_ model: FaceGeometryModel) {
        faceDetectedState = .faceDetected
        faceGeometryState = .faceFound(model)

        let boundingBox = model.boundingBox
        let roll = model.roll.doubleValue
        let pitch = model.pitch.doubleValue
        let yaw = model.yaw.doubleValue

        updateAcceptableBounds(using: boundingBox)
        updateAcceptableRollPitchYaw(using: roll, pitch: pitch, yaw: yaw)

        validateFace()
    }

    func updateQuality(_ model: FaceQualityModel) {
        faceDetectedState = .faceDetected
        faceQualityState = .faceFound(model)

        isAcceptableQuality = model.quality >= 0.2
        validateFace()
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
        timeLeft = 0
        
        timer = Timer
            .publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                
                self.timeLeft += 1
                if self.timeLeft >= self.timerTicksRequired {
                    self.finishStep()
                }
            }
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
        isTimerRunning = false
        timeLeft = 0
    }

    func finishStep() {
        stopTimer()
        guard !stopTakePhoto else { return }

        AudioServicesPlaySystemSound(SystemSoundID(1108))
        shutterReleased.send()
    }

    func takePhoto() {
        print("📸 takePhoto triggered")
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
            timeLeft = 0
            resetFaceDetection()
        } else {
            verificationStage = .success
            stateFace = .successCompleted
            showSuccess()
        }
    }

    func resetSequence() {
        verificationStage = .notStarted
        faceSequence = []
        currentSequenceIndex = 0
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
}

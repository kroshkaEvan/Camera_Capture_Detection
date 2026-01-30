//
//  FileManagerService.swift
//  Camera_Capture_Detection
//
//  Created by Evan Tsvetkov on 10.01.24.
//

import UIKit

protocol FileManagerServiceProtocol {
    func saveSelfie(_ image: UIImage, for state: FaceState) async throws -> URL
    func getAllSelfies() async throws -> [(FaceState, URL)]
    func clearSelfies() async throws
}

final class FileManagerService: FileManagerServiceProtocol {

    static let shared = FileManagerService()

    private let fileManager = FileManager.default
    private let directoryName = "FaceVerificationSelfies"

    private init() {}

    private var selfiesDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName)
    }

    // MARK: - Public API

    func saveSelfie(_ image: UIImage, for state: FaceState) async throws -> URL {
        try createDirectoryIfNeeded()

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw FaceVerificationError.imageSaveFailed
        }

        let fileName = "\(state)_\(Date().timeIntervalSince1970).jpg"
        let fileURL = selfiesDirectory.appendingPathComponent(fileName)

        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func getAllSelfies() async throws -> [(FaceState, URL)] {
        guard fileManager.fileExists(atPath: selfiesDirectory.path) else {
            return []
        }

        let urls = try fileManager.contentsOfDirectory(
            at: selfiesDirectory,
            includingPropertiesForKeys: nil
        )

        return urls.compactMap { url in
            guard let state = extractFaceState(from: url) else { return nil }
            return (state, url)
        }
    }

    func clearSelfies() async throws {
        guard fileManager.fileExists(atPath: selfiesDirectory.path) else { return }
        try fileManager.removeItem(at: selfiesDirectory)
    }

    // MARK: - Helpers

    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: selfiesDirectory.path) {
            try fileManager.createDirectory(
                at: selfiesDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    private func extractFaceState(from url: URL) -> FaceState? {
        let name = url.lastPathComponent
        guard let raw = name.components(separatedBy: "_").first else { return nil }

        switch raw {
        case "faceOnCentre": return .faceOnCentre
        case "faceLeft": return .faceLeft
        case "faceRight": return .faceRight
        case "faceUp": return .faceUp
        case "faceDown": return .faceDown
        default: return nil
        }
    }
}

//
//  ScreenshotOCRService.swift
//  Screenbase
//

import Foundation
import UIKit
import Vision

protocol ScreenshotOCRService: Sendable {
    func recognizeText(in image: UIImage) async throws -> String
}

enum ScreenshotOCRError: Error {
    case invalidImage
    case recognitionFailed
}

struct VisionScreenshotOCRService: ScreenshotOCRService {
    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ScreenshotOCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

struct MockScreenshotOCRService: ScreenshotOCRService {
    var text: String = "Mock OCR line one\nMock OCR line two"
    var delayNanoseconds: UInt64 = 0

    func recognizeText(in _: UIImage) async throws -> String {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return text
    }
}

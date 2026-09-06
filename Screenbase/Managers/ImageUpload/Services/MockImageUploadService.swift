//
//  MockImageUploadService.swift
//  Screenbase
//

import Foundation
import UIKit

/// Class-backed mock so tests can inspect upload history after calls.
@MainActor
final class MockImageUploadService: ImageUploadService {
    var shouldFail = false
    private(set) var uploadedPaths: [String] = []

    func uploadImage(image: UIImage, path: String) async throws -> URL {
        _ = image
        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }
        uploadedPaths.append(path)
        let name = path.hasSuffix(".png") ? path : "\(path).png"
        return URL(string: "https://example.com/mock/\(name)")!
    }
}

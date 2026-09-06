//
//  FirebaseImageUploadService.swift
//  Screenbase
//

import FirebaseStorage
import Foundation
import UIKit

/// Uploads PNG images to Firebase Storage (AIChatCourse-style helper).
struct FirebaseImageUploadService: ImageUploadService {
    private let storage: Storage

    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    func uploadImage(image: UIImage, path: String) async throws -> URL {
        guard let data = image.pngData() else {
            throw URLError(.dataNotAllowed)
        }

        let reference = imageReference(path: path)
        let meta = StorageMetadata()
        meta.contentType = "image/png"
        _ = try await reference.putDataAsync(data, metadata: meta)
        return try await reference.downloadURL()
    }

    private func imageReference(path: String) -> StorageReference {
        let name = path.hasSuffix(".png") ? path : "\(path).png"
        return storage.reference(withPath: name)
    }
}

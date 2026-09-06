//
//  ImageUploadService.swift
//  Screenbase
//

import Foundation
import UIKit

/// Uploads images to remote storage and returns a download URL.
protocol ImageUploadService {
    func uploadImage(image: UIImage, path: String) async throws -> URL
}

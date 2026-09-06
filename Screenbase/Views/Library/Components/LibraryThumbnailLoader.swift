//
//  LibraryThumbnailLoader.swift
//  Screenbase
//

import CoreGraphics
import Observation
import UIKit

/// Caches Photos thumbnails for visible Library tiles.
@MainActor
@Observable
final class LibraryThumbnailLoader {
    private(set) var images: [String: UIImage] = [:]
    /// Asset IDs that finished loading with no image (deleted / unavailable in Photos).
    private(set) var missingAssetIdentifiers: Set<String> = []

    private let photosManager: PhotosManager
    private var inFlight: Set<String> = []
    private let targetSize: CGSize

    init(photosManager: PhotosManager, pointSize: CGFloat = 180, scale: CGFloat) {
        self.photosManager = photosManager
        targetSize = CGSize(width: pointSize * scale, height: pointSize * scale)
    }

    func image(for assetLocalIdentifier: String) -> UIImage? {
        images[assetLocalIdentifier]
    }

    func isMissing(assetLocalIdentifier: String) -> Bool {
        missingAssetIdentifiers.contains(assetLocalIdentifier)
    }

    func loadIfNeeded(assetLocalIdentifier: String) {
        guard images[assetLocalIdentifier] == nil,
              !missingAssetIdentifiers.contains(assetLocalIdentifier),
              !inFlight.contains(assetLocalIdentifier)
        else { return }
        inFlight.insert(assetLocalIdentifier)
        Task {
            let image = await photosManager.thumbnailImage(
                forAssetLocalIdentifier: assetLocalIdentifier,
                targetSize: targetSize
            )
            if let image {
                images[assetLocalIdentifier] = image
                missingAssetIdentifiers.remove(assetLocalIdentifier)
            } else {
                missingAssetIdentifiers.insert(assetLocalIdentifier)
            }
            inFlight.remove(assetLocalIdentifier)
        }
    }
}

//
//  PhotosManager.swift
//  Screenbase
//

import CoreGraphics
import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PhotosManager {
    private let service: any PhotosService
    private let sharedImageStore: (any SharedImageStore)?

    private(set) var authorizationStatus: PhotosAuthorizationStatus

    init(service: any PhotosService, sharedImageStore: (any SharedImageStore)? = nil) {
        self.service = service
        self.sharedImageStore = sharedImageStore
        authorizationStatus = service.authorizationStatus
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = service.authorizationStatus
    }

    func requestAuthorization() async -> PhotosAuthorizationStatus {
        authorizationStatus = await service.requestAuthorization()
        return authorizationStatus
    }

    func screenshotCount() async throws -> Int {
        try await service.screenshotCount()
    }

    func thumbnailImage(forAssetLocalIdentifier localIdentifier: String, targetSize: CGSize) async -> UIImage? {
        if SharedAssetID.isShared(localIdentifier) {
            return sharedImageStore?.loadImage(assetLocalIdentifier: localIdentifier)
        }
        return await service.thumbnailImage(forAssetLocalIdentifier: localIdentifier, targetSize: targetSize)
    }

    func fullImage(forAssetLocalIdentifier localIdentifier: String, targetSize: CGSize) async -> UIImage? {
        if SharedAssetID.isShared(localIdentifier) {
            return sharedImageStore?.loadImage(assetLocalIdentifier: localIdentifier)
        }
        return await service.fullImage(forAssetLocalIdentifier: localIdentifier, targetSize: targetSize)
    }
}

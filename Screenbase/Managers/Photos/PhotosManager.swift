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

    private(set) var authorizationStatus: PhotosAuthorizationStatus

    init(service: any PhotosService) {
        self.service = service
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
        await service.thumbnailImage(forAssetLocalIdentifier: localIdentifier, targetSize: targetSize)
    }

    func fullImage(forAssetLocalIdentifier localIdentifier: String, targetSize: CGSize) async -> UIImage? {
        await service.fullImage(forAssetLocalIdentifier: localIdentifier, targetSize: targetSize)
    }
}

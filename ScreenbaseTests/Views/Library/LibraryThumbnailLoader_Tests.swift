//
//  LibraryThumbnailLoader_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing
import UIKit

@Suite("LibraryThumbnailLoader Tests")
struct LibraryThumbnailLoader_Tests {
    @Test("Nil Photos fetch marks asset missing instead of spinning forever")
    @MainActor
    func nilFetchMarksAssetMissing() async {
        let assetId = ScreenshotRecord.mock.assetLocalIdentifier
        let photos = PhotosManager(service: MockPhotosService(
            status: .authorized,
            missingAssetIdentifiers: [assetId]
        ))
        let sut = LibraryThumbnailLoader(photosManager: photos, scale: 2)

        sut.loadIfNeeded(assetLocalIdentifier: assetId)
        await waitUntil { sut.isMissing(assetLocalIdentifier: assetId) }

        #expect(sut.image(for: assetId) == nil)
        #expect(sut.isMissing(assetLocalIdentifier: assetId))
    }
}

@MainActor
private func waitUntil(
    timeoutNanoseconds: UInt64 = 1_000_000_000,
    condition: @MainActor () -> Bool
) async {
    let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
    while !condition() {
        if DispatchTime.now().uptimeNanoseconds > deadline {
            Issue.record("Timed out waiting for condition")
            return
        }
        await Task.yield()
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}

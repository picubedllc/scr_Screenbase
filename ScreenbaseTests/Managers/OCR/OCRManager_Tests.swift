//
//  OCRManager_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing
import UIKit

@Suite("OCRManager Tests")
struct OCRManager_Tests {
    @Test("Indexes unindexed screenshots and persists OCR text")
    @MainActor
    func indexesUnindexedScreenshots() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let image = try #require(UIImage(systemName: "photo"))
        let photos = PhotosManager(service: MockPhotosService(
            status: .authorized,
            fullImages: [ScreenshotRecord.mock.assetLocalIdentifier: image]
        ))
        let sut = OCRManager(
            service: MockScreenshotOCRService(text: "receipt total $12"),
            metadataManager: metadata,
            photosManager: photos
        )

        sut.enqueueUnindexedScreenshots()
        try await waitUntil {
            metadata.screenshots.first?.ocrIndexedAt != nil
        }

        let record = try #require(metadata.screenshots.first)
        #expect(record.ocrText == "receipt total $12")
        #expect(record.ocrIndexedAt != nil)
        #expect(sut.lastIndexedId == record.id)
    }

    @Test("Skips screenshots that are already indexed")
    @MainActor
    func skipsAlreadyIndexed() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        var record = ScreenshotRecord.mock
        record.ocrText = "already"
        record.ocrIndexedAt = Date(timeIntervalSince1970: 1)
        try await metadata.upsertScreenshot(record)

        let photos = PhotosManager(service: MockPhotosService(status: .authorized))
        let sut = OCRManager(
            service: MockScreenshotOCRService(text: "should not apply"),
            metadataManager: metadata,
            photosManager: photos
        )

        sut.enqueueUnindexedScreenshots()
        try await Task.sleep(nanoseconds: 50_000_000)

        let updated = try #require(metadata.screenshots.first)
        #expect(updated.ocrText == "already")
        #expect(sut.pendingCount == 0)
    }

    @MainActor
    private func waitUntil(
        timeoutNanoseconds: UInt64 = 2_000_000_000,
        condition: @MainActor () -> Bool
    ) async throws {
        let start = DispatchTime.now().uptimeNanoseconds
        while !condition() {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds {
                Issue.record("Timed out waiting for OCR indexing")
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}

@Suite("MetadataManager OCR")
struct MetadataManager_OCR_Tests {
    @Test("updateOCRText persists text and indexed timestamp")
    @MainActor
    func updateOCRTextPersists() async throws {
        let sut = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await sut.upsertScreenshot(.mock)
        try await sut.updateOCRText(screenshotId: ScreenshotRecord.mock.id, text: "hello OCR")

        let record = try #require(sut.screenshots.first)
        #expect(record.ocrText == "hello OCR")
        #expect(record.ocrIndexedAt != nil)
        #expect(sut.screenshotsMatchingOCR(query: "hello").count == 1)
    }
}

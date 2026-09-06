//
//  ScreenshotDetailViewModel_OCRCopy_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing
import UIKit

@Suite("ScreenshotDetailViewModel OCR Copy")
struct ScreenshotDetailViewModel_OCRCopy_Tests {
    @Test("Uses indexed OCR text without re-running Vision")
    @MainActor
    func usesIndexedOCRText() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        var record = ScreenshotRecord.mock
        record.ocrText = "indexed receipt"
        record.ocrIndexedAt = Date()
        try await metadata.upsertScreenshot(record)

        let sut = ScreenshotDetailViewModel(
            screenshotId: record.id,
            metadataManager: metadata,
            photosManager: PhotosManager(service: MockPhotosService()),
            imageTargetSize: CGSize(width: 100, height: 100),
            ocrService: MockScreenshotOCRService(text: "should not run")
        )

        await sut.presentOCRText()

        #expect(sut.ocrDisplayText == "indexed receipt")
        #expect(sut.isOCRTextPresented)
        #expect(!sut.isLoadingOCRText)
    }

    @Test("Copy all writes pasteboard")
    @MainActor
    func copyAllWritesPasteboard() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let sut = ScreenshotDetailViewModel(
            screenshotId: ScreenshotRecord.mock.id,
            metadataManager: metadata,
            photosManager: PhotosManager(service: MockPhotosService()),
            imageTargetSize: CGSize(width: 100, height: 100)
        )
        sut.ocrDisplayText = "copy me"
        sut.copyAllOCRText()

        #expect(sut.didCopyOCRText)
        #expect(UIPasteboard.general.string == "copy me")
    }
}

//
//  ScreenshotOCRService_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing
import UIKit

@Suite("ScreenshotOCRService Tests")
struct ScreenshotOCRService_Tests {
    @Test("Mock OCR returns configured text")
    @MainActor
    func mockOCRReturnsConfiguredText() async throws {
        let sut = MockScreenshotOCRService(text: "hello\nworld")
        let image = try #require(UIImage(systemName: "photo"))
        let text = try await sut.recognizeText(in: image)
        #expect(text == "hello\nworld")
    }
}

@Suite("ScreenshotDetailViewModel OCR Export")
struct ScreenshotDetailViewModel_OCR_Tests {
    @Test("Export OCR text populates share items and lastOCRText")
    @MainActor
    func exportOCRTextPopulatesShareItems() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let image = try #require(UIImage(systemName: "photo"))
        let photos = PhotosManager(service: MockPhotosService(
            status: .authorized,
            fullImages: [ScreenshotRecord.mock.assetLocalIdentifier: image]
        ))
        let sut = ScreenshotDetailViewModel(
            screenshotId: ScreenshotRecord.mock.id,
            metadataManager: metadata,
            photosManager: photos,
            imageTargetSize: CGSize(width: 100, height: 100),
            ocrService: MockScreenshotOCRService(text: "exported line")
        )
        await sut.loadImageIfNeeded()
        await sut.presentShareOCRText()

        #expect(sut.lastOCRText == "exported line")
        #expect(sut.isSharePresented)
        #expect((sut.shareActivityItems.first as? String) == "exported line")
    }
}

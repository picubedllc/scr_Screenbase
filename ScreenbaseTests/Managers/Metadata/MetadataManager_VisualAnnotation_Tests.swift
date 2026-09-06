//
//  MetadataManager_VisualAnnotation_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing
import UIKit

@Suite("MetadataManager Visual Annotation")
struct MetadataManager_VisualAnnotation_Tests {
    @Test("Saving visual annotation stores drawing, uploads, and updates record")
    @MainActor
    func savingVisualAnnotationUpdatesRecordAndUploads() async throws {
        let upload = MockImageUploadService()
        let drawings = InMemoryAnnotationDrawingStore()
        let sut = MetadataManager(
            local: InMemoryLocalMetadataStore(),
            remote: MockMetadataService(),
            drawingStore: drawings,
            imageUpload: upload
        )
        sut.configure(userId: "user_1")
        try await sut.upsertScreenshot(.mock)

        let drawingData = Data("drawing-bytes".utf8)
        let overlay = try #require(UIImage(systemName: "pencil.tip"))

        let uploaded = try await sut.saveVisualAnnotation(
            screenshotId: ScreenshotRecord.mock.id,
            drawingData: drawingData,
            overlayImage: overlay
        )

        #expect(uploaded == true)
        #expect(drawings.loadDrawing(screenshotId: ScreenshotRecord.mock.id) == drawingData)
        #expect(sut.screenshots.first?.hasVisualAnnotation == true)
        #expect(sut.screenshots.first?.visualAnnotationURL?.contains("user_1/annotations/") == true)
        #expect(upload.uploadedPaths.count == 1)
        #expect(sut.lastVisualAnnotationUploadError == nil)
    }

    @Test("Upload failure still keeps local drawing and flag")
    @MainActor
    func uploadFailureKeepsLocalDrawing() async throws {
        let upload = MockImageUploadService()
        upload.shouldFail = true
        let drawings = InMemoryAnnotationDrawingStore()
        let sut = MetadataManager(
            local: InMemoryLocalMetadataStore(),
            remote: MockMetadataService(),
            drawingStore: drawings,
            imageUpload: upload
        )
        sut.configure(userId: "user_1")
        try await sut.upsertScreenshot(.mock)

        let uploaded = try await sut.saveVisualAnnotation(
            screenshotId: ScreenshotRecord.mock.id,
            drawingData: Data("local".utf8),
            overlayImage: #require(UIImage(systemName: "pencil.tip"))
        )

        #expect(uploaded == false)
        #expect(sut.lastVisualAnnotationUploadError != nil)
        #expect(drawings.loadDrawing(screenshotId: ScreenshotRecord.mock.id) == Data("local".utf8))
        #expect(sut.screenshots.first?.hasVisualAnnotation == true)
        #expect(sut.screenshots.first?.visualAnnotationURL == nil)
    }
}

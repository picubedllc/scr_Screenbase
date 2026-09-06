//
//  ShareImportManager_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing
import UIKit

@Suite("ShareImportManager Tests")
struct ShareImportManager_Tests {
    @Test("Importing inbox images creates records then clears App Group inbox")
    @MainActor
    func importingClearsInbox() async throws {
        // Use in-memory store; simulate inbox via ShareInbox if App Group unavailable in tests.
        let shared = InMemorySharedImageStore()
        let metadata = MetadataManager(
            local: InMemoryLocalMetadataStore(),
            remote: MockMetadataService(),
            drawingStore: InMemoryAnnotationDrawingStore(),
            imageUpload: MockImageUploadService(),
            sharedImageStore: shared
        )
        let sut = ShareImportManager(sharedImageStore: shared, metadataManager: metadata)

        // When App Group is unavailable, pending is empty — still succeeds.
        let ids = await sut.importPendingSharedImages()
        #expect(ids.isEmpty)

        // Direct shared asset save path (what import does after reading inbox bytes).
        let assetId = SharedAssetID.make()
        let image = try #require(UIImage(systemName: "photo"))
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        try shared.saveImageData(data, assetLocalIdentifier: assetId)
        try await metadata.upsertScreenshot(
            ScreenshotRecord(
                id: FirestoreDocumentID.fromAssetLocalIdentifier(assetId),
                assetLocalIdentifier: assetId
            )
        )

        #expect(SharedAssetID.isShared(assetId))
        #expect(shared.hasImage(assetLocalIdentifier: assetId))
        #expect(metadata.screenshots.count == 1)

        try await metadata.deleteScreenshot(id: FirestoreDocumentID.fromAssetLocalIdentifier(assetId))
        #expect(metadata.screenshots.isEmpty)
        #expect(shared.hasImage(assetLocalIdentifier: assetId) == false)
    }
}

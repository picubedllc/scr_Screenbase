//
//  LibraryViewModel_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing

@Suite("LibraryViewModel Tests")
struct LibraryViewModel_Tests {
    @Test("Filtered screenshots sort newest first")
    @MainActor
    func filteredScreenshotsSortNewestFirst() async throws {
        // Given
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        let older = ScreenshotRecord(
            id: "old",
            assetLocalIdentifier: "old",
            captureDate: Date(timeIntervalSince1970: 1000)
        )
        let newer = ScreenshotRecord(
            id: "new",
            assetLocalIdentifier: "new",
            captureDate: Date(timeIntervalSince1970: 2000)
        )
        try await metadata.upsertScreenshot(older)
        try await metadata.upsertScreenshot(newer)
        let sut = LibraryViewModel(
            metadataManager: metadata,
            screenshotManager: ScreenshotManager(service: MockScreenshotService(screenshots: []), index: metadata)
        )

        // When / Then
        #expect(sut.filteredScreenshots.map(\.id) == ["new", "old"])
        #expect(sut.contentState == .populated)
    }

    @Test("Collections filter only includes assigned screenshots")
    @MainActor
    func collectionsFilterIncludesAssignedOnly() async throws {
        // Given
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(
            ScreenshotRecord(id: "a", assetLocalIdentifier: "a", collectionIds: [])
        )
        try await metadata.upsertScreenshot(
            ScreenshotRecord(id: "b", assetLocalIdentifier: "b", collectionIds: ["col"])
        )
        let sut = LibraryViewModel(
            metadataManager: metadata,
            screenshotManager: ScreenshotManager(service: MockScreenshotService(screenshots: []), index: metadata)
        )

        // When
        sut.selectFilter(.collections)

        // Then
        #expect(sut.filteredScreenshots.map(\.id) == ["b"])
    }

    @Test("Select mode toggles tile selection instead of opening detail")
    @MainActor
    func selectModeTogglesSelection() async throws {
        // Given
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let sut = LibraryViewModel(
            metadataManager: metadata,
            screenshotManager: ScreenshotManager(service: MockScreenshotService(screenshots: []), index: metadata)
        )

        // When
        sut.toggleSelecting()
        sut.handleTileTap(screenshotId: ScreenshotRecord.mock.id)

        // Then
        #expect(sut.isSelected(ScreenshotRecord.mock.id))
        #expect(sut.detailScreenshotId == nil)

        // When
        sut.toggleSelecting()

        // Then
        #expect(sut.selectedScreenshotIds.isEmpty)
        #expect(sut.isSelecting == false)
    }

    @Test("Long press enters select mode and selects the screenshot")
    @MainActor
    func longPressEntersSelectMode() async throws {
        // Given
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let sut = LibraryViewModel(
            metadataManager: metadata,
            screenshotManager: ScreenshotManager(service: MockScreenshotService(screenshots: []), index: metadata)
        )

        // When
        sut.beginSelecting(screenshotId: ScreenshotRecord.mock.id)

        // Then
        #expect(sut.isSelecting)
        #expect(sut.isSelected(ScreenshotRecord.mock.id))
        #expect(sut.detailScreenshotId == nil)
    }

    @Test("Tap outside select mode opens detail")
    @MainActor
    func tapOpensDetailOutsideSelectMode() async throws {
        // Given
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let sut = LibraryViewModel(
            metadataManager: metadata,
            screenshotManager: ScreenshotManager(service: MockScreenshotService(screenshots: []), index: metadata)
        )

        // When
        sut.handleTileTap(screenshotId: ScreenshotRecord.mock.id)

        // Then
        #expect(sut.detailScreenshotId == ScreenshotRecord.mock.id)
    }

    @Test("Empty library reports empty content state")
    @MainActor
    func emptyLibraryReportsEmptyState() {
        // Given
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        let sut = LibraryViewModel(
            metadataManager: metadata,
            screenshotManager: ScreenshotManager(
                service: MockScreenshotService(screenshots: []),
                index: metadata
            )
        )

        // Then
        #expect(sut.contentState == .empty)
        #expect(sut.filteredScreenshots.isEmpty)
    }

    @Test("Multi-select assign applies collections and tags then exits select mode")
    @MainActor
    func multiSelectAssignAppliesAndExitsSelectMode() async throws {
        // Given
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(ScreenshotRecord(id: "a", assetLocalIdentifier: "a"))
        try await metadata.upsertScreenshot(ScreenshotRecord(id: "b", assetLocalIdentifier: "b"))
        let collection = try await metadata.createCollection(name: "Bugs")
        let tag = try await metadata.createTag(name: "ios")
        let sut = LibraryViewModel(
            metadataManager: metadata,
            screenshotManager: ScreenshotManager(service: MockScreenshotService(screenshots: []), index: metadata)
        )

        // When
        sut.toggleSelecting()
        sut.handleTileTap(screenshotId: "a")
        sut.handleTileTap(screenshotId: "b")
        sut.presentAssignSheet()
        sut.toggleAssignCollection(collection.id)
        sut.toggleAssignTag(tag.id)
        await sut.applyAssignment()

        // Then
        #expect(metadata.screenshots.allSatisfy { $0.collectionIds.contains(collection.id) })
        #expect(metadata.screenshots.allSatisfy { $0.tagIds.contains(tag.id) })
        #expect(sut.isSelecting == false)
        #expect(sut.selectedScreenshotIds.isEmpty)
        #expect(sut.isAssignSheetPresented == false)
    }

    @Test("Deleting selected screenshots removes metadata and exits select mode")
    @MainActor
    func deleteSelectedScreenshotsRemovesMetadata() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(ScreenshotRecord(id: "a", assetLocalIdentifier: "a"))
        try await metadata.upsertScreenshot(ScreenshotRecord(id: "b", assetLocalIdentifier: "b"))
        let sut = LibraryViewModel(
            metadataManager: metadata,
            screenshotManager: ScreenshotManager(service: MockScreenshotService(screenshots: []), index: metadata)
        )

        sut.toggleSelecting()
        sut.handleTileTap(screenshotId: "a")
        sut.handleTileTap(screenshotId: "b")
        await sut.deleteSelectedScreenshots()

        #expect(metadata.screenshots.isEmpty)
        #expect(sut.isSelecting == false)
        #expect(sut.selectedScreenshotIds.isEmpty)
    }
}

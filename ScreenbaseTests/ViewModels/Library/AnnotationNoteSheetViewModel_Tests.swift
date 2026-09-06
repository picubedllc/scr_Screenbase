//
//  AnnotationNoteSheetViewModel_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing

@Suite("AnnotationNoteSheetViewModel Tests")
struct AnnotationNoteSheetViewModel_Tests {
    @Test("Saving annotation and tags persists to metadata")
    @MainActor
    func savingAnnotationAndTagsPersists() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let bug = try await metadata.createTag(name: "bug")
        let design = try await metadata.createTag(name: "design")
        try await metadata.setTags([bug.id], forScreenshot: ScreenshotRecord.mock.id)

        var finished = false
        let sut = AnnotationNoteSheetViewModel(
            screenshotId: ScreenshotRecord.mock.id,
            metadataManager: metadata,
            onFinished: { finished = true }
        )
        sut.draft = "Updated note"
        sut.toggleTag(design.id)

        await sut.save()

        let record = try #require(metadata.screenshots.first)
        #expect(record.annotationText == "Updated note")
        #expect(Set(record.tagIds) == [bug.id, design.id])
        #expect(finished)
    }

    @Test("Skip finishes without changing annotation")
    @MainActor
    func skipFinishesWithoutChangingAnnotation() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)

        var finished = false
        let sut = AnnotationNoteSheetViewModel(
            screenshotId: ScreenshotRecord.mock.id,
            metadataManager: metadata,
            allowsSkip: true,
            onFinished: { finished = true }
        )
        sut.draft = "Should not save"
        sut.skip()

        #expect(finished)
        #expect(metadata.screenshots.first?.annotationText == "Login flow")
    }

    @Test("Suggested tags prefer higher usage")
    @MainActor
    func suggestedTagsPreferHigherUsage() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        let popular = try await metadata.createTag(name: "popular")
        let rare = try await metadata.createTag(name: "rare")

        try await metadata.upsertScreenshot(
            ScreenshotRecord(id: "a", assetLocalIdentifier: "a", tagIds: [popular.id])
        )
        try await metadata.upsertScreenshot(
            ScreenshotRecord(id: "b", assetLocalIdentifier: "b", tagIds: [popular.id, rare.id])
        )
        try await metadata.upsertScreenshot(
            ScreenshotRecord(id: "c", assetLocalIdentifier: "c", tagIds: [popular.id])
        )

        let suggested = AnnotationNoteSheetViewModel.suggestedTags(from: metadata, limit: 8)

        #expect(suggested.map(\.id).first == popular.id)
        #expect(suggested.map(\.id).contains(rare.id))
    }
}

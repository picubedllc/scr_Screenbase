//
//  ScreenshotManager_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing

@Suite("ScreenshotManager Tests")
struct ScreenshotManager_Tests {
    @Test("Initial scan indexes all screenshots from the service")
    @MainActor
    func initialScanIndexesAllScreenshots() async {
        // Given
        let service = MockScreenshotService(screenshots: DiscoveredScreenshot.mocks)
        let index = InMemoryScreenshotIndex()
        let sut = ScreenshotManager(service: service, index: index)

        // When
        let newcomers = await sut.runInitialScan()

        // Then
        #expect(newcomers.count == 3)
        #expect(sut.discoveredScreenshots.count == 3)
        #expect(sut.lastIndexedCount == 3)
        #expect(index.indexedAssetIdentifiers.count == 3)
        #expect(sut.lastError == nil)
    }

    @Test("Second scan does not re-index already indexed screenshots")
    @MainActor
    func secondScanSkipsAlreadyIndexedScreenshots() async {
        // Given
        let service = MockScreenshotService(screenshots: DiscoveredScreenshot.mocks)
        let index = InMemoryScreenshotIndex()
        let sut = ScreenshotManager(service: service, index: index)
        _ = await sut.runInitialScan()

        // When
        let newcomers = await sut.runInitialScan()

        // Then
        #expect(newcomers.isEmpty)
        #expect(sut.lastIndexedCount == 0)
        #expect(index.indexedAssetIdentifiers.count == 3)
        #expect(service.fetchCallCount == 2)
    }

    @Test("Library change indexes only newly discovered screenshots")
    @MainActor
    func libraryChangeIndexesOnlyNewScreenshots() async {
        // Given
        let service = MockScreenshotService(screenshots: [DiscoveredScreenshot.mock])
        let index = InMemoryScreenshotIndex()
        let sut = ScreenshotManager(service: service, index: index)
        await sut.startDiscovery()
        #expect(index.indexedAssetIdentifiers.count == 1)
        #expect(sut.pendingCaptureAnnotationIds.isEmpty)
        await waitUntil { sut.isObserving }

        let newer = DiscoveredScreenshot(
            assetLocalIdentifier: "MOCK/ASSET-NEW",
            creationDate: Date(timeIntervalSince1970: 1_700_000_500)
        )
        service.screenshots = [DiscoveredScreenshot.mock, newer]

        // When
        service.emitLibraryChange()
        await waitUntil { index.indexedAssetIdentifiers.contains(newer.assetLocalIdentifier) }

        // Then
        #expect(index.indexedAssetIdentifiers.count == 2)
        #expect(sut.discoveredScreenshots.count == 2)
        let expectedId = FirestoreDocumentID.fromAssetLocalIdentifier(newer.assetLocalIdentifier)
        #expect(sut.pendingCaptureAnnotationIds == [expectedId])
        sut.stopDiscovery()
    }

    @Test("Initial scan does not enqueue capture annotation prompts")
    @MainActor
    func initialScanDoesNotEnqueueCapturePrompts() async {
        let service = MockScreenshotService(screenshots: DiscoveredScreenshot.mocks)
        let index = InMemoryScreenshotIndex()
        let sut = ScreenshotManager(service: service, index: index)

        _ = await sut.runInitialScan()

        #expect(sut.pendingCaptureAnnotationIds.isEmpty)
        #expect(sut.lastIndexedCount == 3)
    }

    @Test("Acknowledge removes pending capture annotation id")
    @MainActor
    func acknowledgeRemovesPendingCaptureAnnotationId() async throws {
        let service = MockScreenshotService(screenshots: [DiscoveredScreenshot.mock])
        let index = InMemoryScreenshotIndex()
        let sut = ScreenshotManager(service: service, index: index)
        await sut.startDiscovery()
        await waitUntil { sut.isObserving }

        let newer = DiscoveredScreenshot(
            assetLocalIdentifier: "MOCK/ASSET-NEW",
            creationDate: Date()
        )
        service.screenshots = [DiscoveredScreenshot.mock, newer]
        service.emitLibraryChange()
        await waitUntil { !sut.pendingCaptureAnnotationIds.isEmpty }

        let id = try #require(sut.pendingCaptureAnnotationIds.first)
        sut.acknowledgeCaptureAnnotation(id: id)

        #expect(sut.pendingCaptureAnnotationIds.isEmpty)
        sut.stopDiscovery()
    }

    @Test("Unauthorized fetch records notAuthorized and indexes nothing")
    @MainActor
    func unauthorizedFetchRecordsError() async {
        // Given
        let service = MockScreenshotService(screenshots: DiscoveredScreenshot.mocks, isAuthorized: false)
        let index = InMemoryScreenshotIndex()
        let sut = ScreenshotManager(service: service, index: index)

        // When
        let newcomers = await sut.runInitialScan()

        // Then
        #expect(newcomers.isEmpty)
        #expect(sut.lastError == .notAuthorized)
        #expect(index.indexedAssetIdentifiers.isEmpty)
    }

    @Test("Fetch results only contain provided screenshot assets")
    @MainActor
    func fetchResultsOnlyContainScreenshots() async {
        // Given — mock service only returns screenshot-typed assets (live filters by photoScreenshot)
        let screenshots = [
            DiscoveredScreenshot(assetLocalIdentifier: "SHOT/1", creationDate: nil),
            DiscoveredScreenshot(assetLocalIdentifier: "SHOT/2", creationDate: nil)
        ]
        let service = MockScreenshotService(screenshots: screenshots)
        let sut = ScreenshotManager(service: service, index: InMemoryScreenshotIndex())

        // When
        _ = await sut.runInitialScan()

        // Then
        #expect(sut.discoveredScreenshots.map(\.assetLocalIdentifier) == ["SHOT/1", "SHOT/2"])
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

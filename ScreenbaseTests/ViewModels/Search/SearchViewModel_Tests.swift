//
//  SearchViewModel_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing

@Suite("SearchViewModel Tests")
struct SearchViewModel_Tests {
    @Test("Empty query shows recent state")
    @MainActor
    func emptyQueryShowsRecent() async throws {
        let defaults = UserDefaults(suiteName: "SearchViewModelTests.empty")!
        defaults.removePersistentDomain(forName: "SearchViewModelTests.empty")
        let store = RecentSearchStore(defaults: defaults)
        store.add("receipts")

        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        let sut = SearchViewModel(metadataManager: metadata, recentStore: store)
        sut.setSearching(true)

        #expect(sut.contentState == .recent)
        #expect(sut.recentQueries == ["receipts"])
    }

    @Test("Query with no matches shows empty results")
    @MainActor
    func emptyResultsState() async throws {
        let defaults = UserDefaults(suiteName: "SearchViewModelTests.none")!
        defaults.removePersistentDomain(forName: "SearchViewModelTests.none")
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let sut = SearchViewModel(
            metadataManager: metadata,
            recentStore: RecentSearchStore(defaults: defaults)
        )
        sut.setSearching(true)
        sut.query = "zzzz-no-match"

        #expect(sut.contentState == .emptyResults)
        #expect(sut.results.isEmpty)
    }

    @Test("Annotation match returns results")
    @MainActor
    func annotationMatchReturnsResults() async throws {
        let defaults = UserDefaults(suiteName: "SearchViewModelTests.match")!
        defaults.removePersistentDomain(forName: "SearchViewModelTests.match")
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        try await metadata.upsertScreenshot(.mock)
        let sut = SearchViewModel(
            metadataManager: metadata,
            recentStore: RecentSearchStore(defaults: defaults)
        )
        sut.setSearching(true)
        sut.query = "login"

        #expect(sut.contentState == .results)
        #expect(sut.results.map(\.id) == [ScreenshotRecord.mock.id])
        #expect(sut.results.first?.matchSources.contains("Note") == true)
    }

    @Test("OCR text is searchable")
    @MainActor
    func ocrTextIsSearchable() async throws {
        let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
        var record = ScreenshotRecord.mock
        record.annotationText = nil
        record.ocrText = "Starbucks latte"
        record.ocrIndexedAt = Date()
        try await metadata.upsertScreenshot(record)

        let items = SearchViewModel.search(query: "starbucks", metadata: metadata)
        #expect(items.count == 1)
        #expect(items.first?.matchSources.contains("OCR") == true)
    }
}

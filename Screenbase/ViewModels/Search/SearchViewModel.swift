//
//  SearchViewModel.swift
//  Screenbase
//

import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    enum ContentState: Equatable {
        case landing
        case recent
        case emptyResults
        case results
    }

    struct ResultItem: Identifiable, Equatable, Hashable {
        let id: String
        let assetLocalIdentifier: String
        let matchSources: [String]
    }

    private let metadataManager: MetadataManager
    private let recentStore: RecentSearchStore

    var query: String = "" {
        didSet { refreshResults() }
    }

    private(set) var recentQueries: [String] = []
    private(set) var results: [ResultItem] = []
    private(set) var contentState: ContentState = .landing
    private(set) var detailScreenshotId: String?

    init(metadataManager: MetadataManager, recentStore: RecentSearchStore = .shared) {
        self.metadataManager = metadataManager
        self.recentStore = recentStore
        recentQueries = recentStore.load()
    }

    func setSearching(_ isSearching: Bool) {
        if !isSearching {
            contentState = .landing
            return
        }
        refreshResults()
    }

    func selectRecent(_ recent: String) {
        query = recent
        commitSearch()
    }

    func clearRecent() {
        recentStore.clear()
        recentQueries = []
        refreshResults()
    }

    func commitSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentStore.add(trimmed)
        recentQueries = recentStore.load()
        refreshResults()
    }

    func openDetail(id: String) {
        detailScreenshotId = id
        commitSearch()
    }

    func clearDetail() {
        detailScreenshotId = nil
    }

    private func refreshResults() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = []
            contentState = .recent
            return
        }

        results = Self.search(query: trimmed, metadata: metadataManager)
        contentState = results.isEmpty ? .emptyResults : .results
    }

    /// Basic multi-source match (SCR-15). SCR-16 upgrades to ranked relevance.
    static func search(query: String, metadata: MetadataManager) -> [ResultItem] {
        let tagsById = Dictionary(uniqueKeysWithValues: metadata.tags.map { ($0.id, $0) })
        let collectionsById = Dictionary(uniqueKeysWithValues: metadata.collections.map { ($0.id, $0) })

        var items: [ResultItem] = []
        for record in metadata.screenshots {
            var sources: [String] = []
            if (record.annotationText ?? "").localizedCaseInsensitiveContains(query) {
                sources.append("Note")
            }
            if (record.ocrText ?? "").localizedCaseInsensitiveContains(query) {
                sources.append("OCR")
            }
            for tagId in record.tagIds {
                if let name = tagsById[tagId]?.name,
                   name.localizedCaseInsensitiveContains(query) {
                    sources.append("Tag")
                    break
                }
            }
            for collectionId in record.collectionIds {
                if let name = collectionsById[collectionId]?.name,
                   name.localizedCaseInsensitiveContains(query) {
                    sources.append("Collection")
                    break
                }
            }
            guard !sources.isEmpty else { continue }
            items.append(
                ResultItem(
                    id: record.id,
                    assetLocalIdentifier: record.assetLocalIdentifier,
                    matchSources: sources
                )
            )
        }
        return items
    }
}

struct RecentSearchStore: Sendable {
    static let shared = RecentSearchStore()

    private let defaults: UserDefaults
    private let key = "screenbase.recentSearches"
    private let limit = 8

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func add(_ query: String) {
        var next = load().filter { $0.caseInsensitiveCompare(query) != .orderedSame }
        next.insert(query, at: 0)
        if next.count > limit {
            next = Array(next.prefix(limit))
        }
        defaults.set(next, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

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
        let score: Int
    }

    private let metadataManager: MetadataManager
    private let recentStore: RecentSearchStore
    private let searchEngine = RankedSearchEngine()
    /// Free/Pro gate for OCR hits (SCR-24). Default true until PurchaseManager gating ships.
    var includeOCRInSearch: Bool = true

    private var refreshTask: Task<Void, Never>?

    var query: String = "" {
        didSet {
            scheduleRefresh()
        }
    }

    private(set) var recentQueries: [String] = []
    private(set) var results: [ResultItem] = []
    private(set) var contentState: ContentState = .landing
    private(set) var detailScreenshotId: String?
    /// Last measured query latency (nanoseconds) for diagnostics / SCR-17.
    private(set) var lastQueryElapsedNanoseconds: UInt64 = 0

    init(metadataManager: MetadataManager, recentStore: RecentSearchStore = .shared) {
        self.metadataManager = metadataManager
        self.recentStore = recentStore
        recentQueries = recentStore.load()
    }

    func setSearching(_ isSearching: Bool) {
        if !isSearching {
            refreshTask?.cancel()
            contentState = .landing
            return
        }
        scheduleRefresh(immediate: true)
    }

    func selectRecent(_ recent: String) {
        query = recent
        commitSearch()
    }

    func clearRecent() {
        recentStore.clear()
        recentQueries = []
        scheduleRefresh(immediate: true)
    }

    func commitSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentStore.add(trimmed)
        recentQueries = recentStore.load()
        scheduleRefresh(immediate: true)
    }

    func openDetail(id: String) {
        detailScreenshotId = id
        commitSearch()
    }

    func clearDetail() {
        detailScreenshotId = nil
    }

    private func scheduleRefresh(immediate: Bool = false) {
        refreshTask?.cancel()
        if immediate {
            refreshResults()
            return
        }
        refreshTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            refreshResults()
        }
    }

    private func refreshResults() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = []
            lastQueryElapsedNanoseconds = 0
            contentState = .recent
            return
        }

        let input = RankedSearchEngine.Input(
            screenshots: metadataManager.screenshots,
            tags: metadataManager.tags,
            collections: metadataManager.collections,
            includeOCR: includeOCRInSearch
        )
        let timing = SearchPerformanceProbe.measureQuery(
            query: trimmed,
            input: input,
            engine: searchEngine
        )
        lastQueryElapsedNanoseconds = timing.elapsedNanoseconds
        results = searchEngine.search(query: trimmed, in: input).map {
            ResultItem(
                id: $0.screenshotId,
                assetLocalIdentifier: $0.assetLocalIdentifier,
                matchSources: $0.matchSources,
                score: $0.score
            )
        }
        contentState = results.isEmpty ? .emptyResults : .results
        #if DEBUG
        if lastQueryElapsedNanoseconds > 0 {
            let ms = Double(lastQueryElapsedNanoseconds) / 1_000_000
            print(String(format: "[Screenbase Search] \"%@\" → %d hits in %.1f ms", trimmed, results.count, ms))
        }
        #endif
    }

    static func search(
        query: String,
        metadata: MetadataManager,
        includeOCR: Bool = true,
        engine: RankedSearchEngine = RankedSearchEngine()
    ) -> [ResultItem] {
        let hits = engine.search(
            query: query,
            in: RankedSearchEngine.Input(
                screenshots: metadata.screenshots,
                tags: metadata.tags,
                collections: metadata.collections,
                includeOCR: includeOCR
            )
        )
        return hits.map {
            ResultItem(
                id: $0.screenshotId,
                assetLocalIdentifier: $0.assetLocalIdentifier,
                matchSources: $0.matchSources,
                score: $0.score
            )
        }
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

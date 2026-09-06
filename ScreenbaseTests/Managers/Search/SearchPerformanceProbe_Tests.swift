//
//  SearchPerformanceProbe_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing

@Suite("SearchPerformanceProbe Tests")
struct SearchPerformanceProbe_Tests {
    @Test("Corpus stats scale with library size")
    func corpusStatsScale() {
        let records = (0 ..< 100).map { index in
            ScreenshotRecord(
                id: "id-\(index)",
                assetLocalIdentifier: "ASSET-\(index)",
                annotationText: String(repeating: "a", count: 20),
                ocrText: String(repeating: "b", count: 40),
                ocrIndexedAt: Date()
            )
        }
        let stats = SearchPerformanceProbe.corpusStats(from: records)
        #expect(stats.screenshotCount == 100)
        #expect(stats.indexedOCRCount == 100)
        #expect(stats.annotationCharacters == 2_000)
        #expect(stats.ocrCharacters == 4_000)
        #expect(stats.averageSearchCharactersPerScreenshot == 60)
    }

    @Test("1k screenshot query stays within interactive budget")
    func thousandScreenshotQueryBudget() {
        let records = (0 ..< 1_000).map { index -> ScreenshotRecord in
            ScreenshotRecord(
                id: "id-\(index)",
                assetLocalIdentifier: "ASSET-\(index)",
                captureDate: Date(timeIntervalSince1970: Double(index)),
                annotationText: index.isMultiple(of: 50) ? "receipt #\(index)" : "note \(index)",
                ocrText: "ocr body \(index) " + String(repeating: "x", count: 80),
                ocrIndexedAt: Date()
            )
        }

        let timing = SearchPerformanceProbe.measureQuery(
            query: "receipt",
            input: RankedSearchEngine.Input(
                screenshots: records,
                tags: [],
                collections: []
            )
        )

        #expect(timing.hitCount > 0)
        #expect(timing.elapsedNanoseconds < SearchPerformanceProbe.Budget.queryLatencyNanoseconds)

        let stats = SearchPerformanceProbe.corpusStats(from: records)
        #expect(stats.averageSearchCharactersPerScreenshot < Double(SearchPerformanceProbe.Budget.corpusCharactersPerScreenshot))
    }
}

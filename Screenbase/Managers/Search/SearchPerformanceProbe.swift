//
//  SearchPerformanceProbe.swift
//  Screenbase
//

import Foundation

/// Metrics + timing helpers for SCR-17 search performance pass.
enum SearchPerformanceProbe {
    /// Soft ceilings documented for a mid-size library (~1k screenshots) on-device.
    enum Budget {
        /// Ranked query over an in-memory corpus should stay interactive.
        static let queryLatencyNanoseconds: UInt64 = 100_000_000 // 100 ms
        /// Rough UTF-16 unit budget for OCR + notes (not a hard crash limit).
        static let corpusCharactersPerScreenshot: Int = 8_000
    }

    struct CorpusStats: Equatable, Sendable {
        var screenshotCount: Int
        var indexedOCRCount: Int
        var annotationCharacters: Int
        var ocrCharacters: Int

        var totalSearchCharacters: Int { annotationCharacters + ocrCharacters }

        var averageSearchCharactersPerScreenshot: Double {
            guard screenshotCount > 0 else { return 0 }
            return Double(totalSearchCharacters) / Double(screenshotCount)
        }
    }

    struct QueryTiming: Equatable, Sendable {
        var hitCount: Int
        var elapsedNanoseconds: UInt64
    }

    static func corpusStats(from screenshots: [ScreenshotRecord]) -> CorpusStats {
        var annotationCharacters = 0
        var ocrCharacters = 0
        var indexedOCRCount = 0
        for record in screenshots {
            annotationCharacters += record.annotationText?.count ?? 0
            if record.ocrIndexedAt != nil {
                indexedOCRCount += 1
                ocrCharacters += record.ocrText?.count ?? 0
            }
        }
        return CorpusStats(
            screenshotCount: screenshots.count,
            indexedOCRCount: indexedOCRCount,
            annotationCharacters: annotationCharacters,
            ocrCharacters: ocrCharacters
        )
    }

    static func measureQuery(
        query: String,
        input: RankedSearchEngine.Input,
        engine: RankedSearchEngine = RankedSearchEngine()
    ) -> QueryTiming {
        let start = DispatchTime.now().uptimeNanoseconds
        let hits = engine.search(query: query, in: input)
        let elapsed = DispatchTime.now().uptimeNanoseconds &- start
        return QueryTiming(hitCount: hits.count, elapsedNanoseconds: elapsed)
    }
}

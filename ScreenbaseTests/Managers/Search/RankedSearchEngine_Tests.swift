//
//  RankedSearchEngine_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing

@Suite("RankedSearchEngine Tests")
struct RankedSearchEngine_Tests {
    private let engine = RankedSearchEngine()

    @Test("Ranks annotation hits above OCR-only hits")
    func ranksAnnotationAboveOCR() {
        let annotationHit = ScreenshotRecord(
            id: "a",
            assetLocalIdentifier: "A",
            captureDate: Date(timeIntervalSince1970: 100),
            annotationText: "receipt from store"
        )
        let ocrHit = ScreenshotRecord(
            id: "b",
            assetLocalIdentifier: "B",
            captureDate: Date(timeIntervalSince1970: 200),
            ocrText: "receipt total 12.00",
            ocrIndexedAt: Date()
        )

        let hits = engine.search(
            query: "receipt",
            in: RankedSearchEngine.Input(
                screenshots: [ocrHit, annotationHit],
                tags: [],
                collections: []
            )
        )

        #expect(hits.map(\.screenshotId) == ["a", "b"])
        #expect(hits[0].score > hits[1].score)
    }

    @Test("Multi-source matches get a bonus and can outrank single OCR")
    func multiSourceBonus() {
        let dual = ScreenshotRecord(
            id: "dual",
            assetLocalIdentifier: "D",
            annotationText: "ads",
            ocrText: "summer sale ads",
            ocrIndexedAt: Date(),
            tagIds: ["t1"]
        )
        let ocrOnly = ScreenshotRecord(
            id: "ocr",
            assetLocalIdentifier: "O",
            ocrText: "ads everywhere",
            ocrIndexedAt: Date()
        )
        let tag = TagRecord(id: "t1", name: "Ads")

        let hits = engine.search(
            query: "ads",
            in: RankedSearchEngine.Input(
                screenshots: [ocrOnly, dual],
                tags: [tag],
                collections: []
            )
        )

        #expect(hits.first?.screenshotId == "dual")
        #expect(hits.first?.matchSources.count ?? 0 >= 2)
    }

    @Test("includeOCR false excludes OCR matches")
    func freeTierExcludesOCR() {
        let ocrOnly = ScreenshotRecord(
            id: "ocr",
            assetLocalIdentifier: "O",
            ocrText: "boarding pass",
            ocrIndexedAt: Date()
        )
        let note = ScreenshotRecord(
            id: "note",
            assetLocalIdentifier: "N",
            annotationText: "boarding"
        )

        let hits = engine.search(
            query: "boarding",
            in: RankedSearchEngine.Input(
                screenshots: [ocrOnly, note],
                tags: [],
                collections: [],
                includeOCR: false
            )
        )

        #expect(hits.map(\.screenshotId) == ["note"])
    }

    @Test("Equal scores break ties by newer capture date")
    func tieBreakByRecency() {
        let older = ScreenshotRecord(
            id: "old",
            assetLocalIdentifier: "OLD",
            captureDate: Date(timeIntervalSince1970: 1),
            annotationText: "login"
        )
        let newer = ScreenshotRecord(
            id: "new",
            assetLocalIdentifier: "NEW",
            captureDate: Date(timeIntervalSince1970: 99),
            annotationText: "login"
        )

        let hits = engine.search(
            query: "login",
            in: RankedSearchEngine.Input(
                screenshots: [older, newer],
                tags: [],
                collections: []
            )
        )

        #expect(hits.map(\.screenshotId) == ["new", "old"])
    }
}

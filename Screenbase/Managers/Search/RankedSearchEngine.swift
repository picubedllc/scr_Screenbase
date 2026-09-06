//
//  RankedSearchEngine.swift
//  Screenbase
//

import Foundation

/// Multi-source relevance ranking for global search (SCR-16).
struct RankedSearchEngine: Sendable {
    struct Input: Sendable {
        var screenshots: [ScreenshotRecord]
        var tags: [TagRecord]
        var collections: [CollectionRecord]
        /// When false, OCR matches are ignored (Free tier). Default true for Pro / trial.
        var includeOCR: Bool = true
    }

    struct Hit: Equatable, Sendable {
        var screenshotId: String
        var assetLocalIdentifier: String
        var score: Int
        var matchSources: [String]
    }

    /// Weights favor intentional user metadata over OCR body text.
    private enum Weight {
        static let annotation = 100
        static let tag = 90
        static let collection = 80
        static let ocr = 40
        static let multiSourceBonus = 25
    }

    func search(query: String, in input: Input) -> [Hit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let tagsById = Dictionary(uniqueKeysWithValues: input.tags.map { ($0.id, $0) })
        let collectionsById = Dictionary(uniqueKeysWithValues: input.collections.map { ($0.id, $0) })

        var hits: [Hit] = []
        for record in input.screenshots {
            var score = 0
            var sources: [String] = []

            if matches(trimmed, in: record.annotationText) {
                score += Weight.annotation
                sources.append("Note")
            }

            if input.includeOCR, matches(trimmed, in: record.ocrText) {
                score += Weight.ocr
                sources.append("OCR")
            }

            for tagId in record.tagIds {
                if let name = tagsById[tagId]?.name, matches(trimmed, in: name) {
                    score += Weight.tag
                    sources.append("Tag")
                    break
                }
            }

            for collectionId in record.collectionIds {
                if let name = collectionsById[collectionId]?.name, matches(trimmed, in: name) {
                    score += Weight.collection
                    sources.append("Collection")
                    break
                }
            }

            guard score > 0 else { continue }
            if sources.count > 1 {
                score += Weight.multiSourceBonus
            }

            hits.append(
                Hit(
                    screenshotId: record.id,
                    assetLocalIdentifier: record.assetLocalIdentifier,
                    score: score,
                    matchSources: sources
                )
            )
        }

        let dates = Dictionary(uniqueKeysWithValues: input.screenshots.map {
            ($0.id, $0.captureDate ?? $0.createdAt)
        })

        return hits.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            let ld = dates[lhs.screenshotId] ?? .distantPast
            let rd = dates[rhs.screenshotId] ?? .distantPast
            return ld > rd
        }
    }

    private func matches(_ query: String, in text: String?) -> Bool {
        guard let text, !text.isEmpty else { return false }
        return text.localizedCaseInsensitiveContains(query)
    }
}

//
//  AnnotationNoteSheetViewModel.swift
//  Screenbase
//

import Foundation
import Observation

@MainActor
@Observable
final class AnnotationNoteSheetViewModel: Identifiable {
    var id: String { screenshotId }

    var draft: String
    var selectedTagIds: Set<String>

    let screenshotId: String
    let title: String
    let allowsSkip: Bool
    let suggestedTags: [TagRecord]

    private let metadataManager: MetadataManager
    private let onFinished: () -> Void

    init(
        screenshotId: String,
        metadataManager: MetadataManager,
        title: String = "Notes",
        allowsSkip: Bool = false,
        initialDraft: String? = nil,
        initialTagIds: Set<String>? = nil,
        suggestedTagLimit: Int = 8,
        onFinished: @escaping () -> Void = {}
    ) {
        self.screenshotId = screenshotId
        self.metadataManager = metadataManager
        self.title = title
        self.allowsSkip = allowsSkip
        self.onFinished = onFinished

        let record = metadataManager.screenshots.first { $0.id == screenshotId }
        draft = initialDraft ?? record?.annotationText ?? ""
        selectedTagIds = initialTagIds ?? Set(record?.tagIds ?? [])
        suggestedTags = Self.suggestedTags(from: metadataManager, limit: suggestedTagLimit)
    }

    var canSave: Bool {
        true
    }

    func toggleTag(_ id: String) {
        if selectedTagIds.contains(id) {
            selectedTagIds.remove(id)
        } else {
            selectedTagIds.insert(id)
        }
    }

    func save() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        try? await metadataManager.updateAnnotation(
            screenshotId: screenshotId,
            text: trimmed.isEmpty ? nil : trimmed
        )
        try? await metadataManager.setTags(Array(selectedTagIds), forScreenshot: screenshotId)
        onFinished()
    }

    func skip() {
        onFinished()
    }

    static func suggestedTags(from metadataManager: MetadataManager, limit: Int) -> [TagRecord] {
        var usage: [String: Int] = [:]
        for screenshot in metadataManager.screenshots {
            for tagId in screenshot.tagIds {
                usage[tagId, default: 0] += 1
            }
        }

        return metadataManager.tags
            .sorted { lhs, rhs in
                let left = usage[lhs.id] ?? 0
                let right = usage[rhs.id] ?? 0
                if left != right { return left > right }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(limit)
            .map { $0 }
    }
}

//
//  LibraryViewModel.swift
//  Screenbase
//

import Foundation
import Observation

@MainActor
@Observable
final class LibraryViewModel {
    enum ContentState: Equatable {
        case loading
        case empty
        case populated
    }

    var selectedFilter: LibraryFilter = .all
    var isSelecting = false
    var selectedScreenshotIds: Set<String> = []
    var isAddSheetPresented = false
    var isAssignSheetPresented = false
    var selectedAssignCollectionIds: Set<String> = []
    var selectedAssignTagIds: Set<String> = []
    var assignNameEditorMode: AssignNameEditorMode?
    var assignNameDraft = ""
    var detailScreenshotId: String?

    enum AssignNameEditorMode: Equatable {
        case collection
        case tag
    }

    private let metadataManager: MetadataManager
    private let screenshotManager: ScreenshotManager
    private let favoriteTagName = "favorite"
    private let recentInterval: TimeInterval = 7 * 24 * 60 * 60

    init(metadataManager: MetadataManager, screenshotManager: ScreenshotManager) {
        self.metadataManager = metadataManager
        self.screenshotManager = screenshotManager
    }

    var contentState: ContentState {
        if !filteredScreenshots.isEmpty {
            return .populated
        }
        if screenshotManager.isScanning, metadataManager.screenshots.isEmpty {
            return .loading
        }
        return .empty
    }

    /// Newest capture first (falls back to createdAt).
    var filteredScreenshots: [ScreenshotRecord] {
        let sorted = metadataManager.screenshots.sorted { lhs, rhs in
            let left = lhs.captureDate ?? lhs.createdAt
            let right = rhs.captureDate ?? rhs.createdAt
            return left > right
        }

        switch selectedFilter {
        case .all:
            return sorted
        case .collections:
            return sorted.filter { !$0.collectionIds.isEmpty }
        case .favorites:
            let favoriteIds = Set(
                metadataManager.tags
                    .filter {
                        $0.name
                            .compare(favoriteTagName, options: [.caseInsensitive, .diacriticInsensitive]) ==
                            .orderedSame
                    }
                    .map(\.id)
            )
            return sorted.filter { record in
                record.tagIds.contains { favoriteIds.contains($0) }
            }
        case .recent:
            let cutoff = Date().addingTimeInterval(-recentInterval)
            return sorted.filter { ($0.captureDate ?? $0.createdAt) >= cutoff }
        }
    }

    var skeletonTileCount: Int {
        12
    }

    var selectionCount: Int {
        selectedScreenshotIds.count
    }

    var canPresentAssignSheet: Bool {
        isSelecting && !selectedScreenshotIds.isEmpty
    }

    var canDeleteSelection: Bool {
        isSelecting && !selectedScreenshotIds.isEmpty
    }

    var assignableCollections: [CollectionRecord] {
        metadataManager.collections.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var assignableTags: [TagRecord] {
        metadataManager.tags.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var canApplyAssignment: Bool {
        !selectedAssignCollectionIds.isEmpty || !selectedAssignTagIds.isEmpty
    }

    var isAssignNameEditorPresented: Bool {
        get { assignNameEditorMode != nil }
        set {
            if !newValue {
                assignNameEditorMode = nil
                assignNameDraft = ""
            }
        }
    }

    var assignNameEditorTitle: String {
        switch assignNameEditorMode {
        case .collection: "New Collection"
        case .tag: "New Tag"
        case nil: ""
        }
    }

    var canSaveAssignName: Bool {
        !assignNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func selectFilter(_ filter: LibraryFilter) {
        selectedFilter = filter
    }

    func toggleSelecting() {
        isSelecting.toggle()
        if !isSelecting {
            selectedScreenshotIds.removeAll()
            isAssignSheetPresented = false
            resetAssignDraft()
        }
    }

    /// Enters select mode and selects the long-pressed screenshot.
    func beginSelecting(screenshotId: String) {
        guard !isSelecting else {
            handleTileTap(screenshotId: screenshotId)
            return
        }
        isSelecting = true
        selectedScreenshotIds = [screenshotId]
        HapticsManager.instance.mediumImpact()
    }

    func handleTileTap(screenshotId: String) {
        if isSelecting {
            if selectedScreenshotIds.contains(screenshotId) {
                selectedScreenshotIds.remove(screenshotId)
            } else {
                selectedScreenshotIds.insert(screenshotId)
            }
            HapticsManager.instance.lightImpact()
        } else {
            detailScreenshotId = screenshotId
        }
    }

    func isSelected(_ screenshotId: String) -> Bool {
        selectedScreenshotIds.contains(screenshotId)
    }

    func presentAddSheet() {
        isAddSheetPresented = true
    }

    func presentAssignSheet() {
        guard canPresentAssignSheet else { return }
        resetAssignDraft()
        isAssignSheetPresented = true
    }

    func toggleAssignCollection(_ id: String) {
        if selectedAssignCollectionIds.contains(id) {
            selectedAssignCollectionIds.remove(id)
        } else {
            selectedAssignCollectionIds.insert(id)
        }
    }

    func toggleAssignTag(_ id: String) {
        if selectedAssignTagIds.contains(id) {
            selectedAssignTagIds.remove(id)
        } else {
            selectedAssignTagIds.insert(id)
        }
    }

    func presentCreateAssignCollection() {
        assignNameDraft = ""
        assignNameEditorMode = .collection
    }

    func presentCreateAssignTag() {
        assignNameDraft = ""
        assignNameEditorMode = .tag
    }

    func saveAssignNameEditor() async {
        let draft = assignNameDraft
        guard let mode = assignNameEditorMode else { return }
        do {
            switch mode {
            case .collection:
                let collection = try await metadataManager.createCollection(name: draft)
                selectedAssignCollectionIds.insert(collection.id)
            case .tag:
                let tag = try await metadataManager.createTag(name: draft)
                selectedAssignTagIds.insert(tag.id)
            }
            assignNameEditorMode = nil
            assignNameDraft = ""
        } catch {
            // Keep editor open for empty/invalid names.
        }
    }

    func applyAssignment() async {
        let screenshotIds = Array(selectedScreenshotIds)
        let collectionIds = Array(selectedAssignCollectionIds)
        let tagIds = Array(selectedAssignTagIds)
        guard !screenshotIds.isEmpty, !collectionIds.isEmpty || !tagIds.isEmpty else { return }

        try? await metadataManager.assignCollections(collectionIds, toScreenshots: screenshotIds)
        try? await metadataManager.assignTags(tagIds, toScreenshots: screenshotIds)

        isAssignSheetPresented = false
        resetAssignDraft()
        isSelecting = false
        selectedScreenshotIds.removeAll()
    }

    /// Removes selected screenshot metadata entries (Photos originals are untouched).
    func deleteSelectedScreenshots() async {
        let ids = Array(selectedScreenshotIds)
        guard !ids.isEmpty else { return }
        for id in ids {
            try? await metadataManager.deleteScreenshot(id: id)
        }
        selectedScreenshotIds.removeAll()
        isSelecting = false
        isAssignSheetPresented = false
        resetAssignDraft()
    }

    func clearDetail() {
        detailScreenshotId = nil
    }

    private func resetAssignDraft() {
        selectedAssignCollectionIds.removeAll()
        selectedAssignTagIds.removeAll()
        assignNameEditorMode = nil
        assignNameDraft = ""
    }
}

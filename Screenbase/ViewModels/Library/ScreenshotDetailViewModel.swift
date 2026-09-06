//
//  ScreenshotDetailViewModel.swift
//  Screenbase
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ScreenshotDetailViewModel {
    enum ImageState: Equatable {
        case loading
        case loaded
        case missing
    }

    enum MembershipSheetMode: Equatable {
        case tags
        case collections
    }

    let screenshotId: String

    var image: UIImage?
    var imageState: ImageState = .loading
    var overlayImage: UIImage?
    var areAnnotationsVisible: Bool
    var isAnnotationEditorPresented = false
    var isMarkupEditorPresented = false
    var membershipSheetMode: MembershipSheetMode?
    var selectedCollectionIds: Set<String> = []
    var selectedTagIds: Set<String> = []
    var membershipNameEditorMode: MembershipNameEditorMode?
    var membershipNameDraft = ""
    var isSharePresented = false
    var isFullscreenPresented = false
    var isOCRTextPresented = false
    var isLoadingOCRText = false
    var ocrDisplayText: String?
    var didCopyOCRText = false
    var ocrLoadError: String?

    enum MembershipNameEditorMode: Equatable {
        case collection
        case tag
    }

    private let metadataManager: MetadataManager
    private let photosManager: PhotosManager
    private let imageTargetSize: CGSize
    private let ocrService: any ScreenshotOCRService

    init(
        screenshotId: String,
        metadataManager: MetadataManager,
        photosManager: PhotosManager,
        imageTargetSize: CGSize,
        showAnnotationsByDefault: Bool = UserDefaults.standard.bool(
            forKey: SettingsViewModel.Keys.showAnnotationsByDefault
        ),
        ocrService: any ScreenshotOCRService = VisionScreenshotOCRService()
    ) {
        self.screenshotId = screenshotId
        self.metadataManager = metadataManager
        self.photosManager = photosManager
        self.imageTargetSize = imageTargetSize
        self.ocrService = ocrService
        areAnnotationsVisible = showAnnotationsByDefault
    }

    var screenshot: ScreenshotRecord? {
        metadataManager.screenshots.first { $0.id == screenshotId }
    }

    var allCollections: [CollectionRecord] {
        metadataManager.collections.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var allTags: [TagRecord] {
        metadataManager.tags.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var canShare: Bool {
        image != nil
    }

    var canOpenFullscreen: Bool {
        image != nil
    }

    var canMarkup: Bool {
        image != nil
    }

    var hasVisualAnnotation: Bool {
        screenshot?.hasVisualAnnotation == true
    }

    /// Image passed to the share sheet — annotated when On, original when Original.
    var shareImage: UIImage? {
        guard let image else { return nil }
        guard areAnnotationsVisible, let overlayImage else { return image }
        return AnnotationCompositor.composite(base: image, overlay: overlayImage)
    }

    /// Image shown in detail / fullscreen respecting the On/Original toggle.
    var displayedImage: UIImage? {
        guard let image else { return nil }
        guard areAnnotationsVisible, let overlayImage else { return image }
        return AnnotationCompositor.composite(base: image, overlay: overlayImage)
    }

    var isMembershipSheetPresented: Bool {
        get { membershipSheetMode != nil }
        set {
            if !newValue {
                membershipSheetMode = nil
                membershipNameEditorMode = nil
                membershipNameDraft = ""
            }
        }
    }

    var membershipSheetTitle: String {
        switch membershipSheetMode {
        case .tags: "Tags"
        case .collections: "Collections"
        case nil: ""
        }
    }

    var isMembershipNameEditorPresented: Bool {
        get { membershipNameEditorMode != nil }
        set {
            if !newValue {
                membershipNameEditorMode = nil
                membershipNameDraft = ""
            }
        }
    }

    var membershipNameEditorTitle: String {
        switch membershipNameEditorMode {
        case .collection: "New Collection"
        case .tag: "New Tag"
        case nil: ""
        }
    }

    var canSaveMembershipName: Bool {
        !membershipNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isNotesActionActive: Bool {
        isAnnotationEditorPresented
    }

    var isMarkupActionActive: Bool {
        isMarkupEditorPresented
    }

    var isTagsActionActive: Bool {
        membershipSheetMode == .tags
    }

    var isCollectionsActionActive: Bool {
        membershipSheetMode == .collections
    }

    var isShareActionActive: Bool {
        isSharePresented
    }

    var isOCRTextActionActive: Bool {
        isOCRTextPresented
    }

    var canShowOCRText: Bool {
        image != nil || screenshot?.ocrIndexedAt != nil
    }

    func loadImageIfNeeded() async {
        guard imageState == .loading || (imageState == .loaded && image == nil) else { return }
        guard let assetId = screenshot?.assetLocalIdentifier else {
            imageState = .missing
            return
        }
        imageState = .loading
        let loaded = await photosManager.fullImage(
            forAssetLocalIdentifier: assetId,
            targetSize: imageTargetSize
        )
        image = loaded
        imageState = loaded == nil ? .missing : .loaded
        refreshOverlayImage()
    }

    func refreshOverlayImage() {
        guard hasVisualAnnotation, let image else {
            overlayImage = nil
            return
        }
        if let data = metadataManager.loadDrawingData(screenshotId: screenshotId),
           let overlay = AnnotationCompositor.overlayImage(
               from: data,
               canvasSize: image.size,
               scale: image.scale
           )
        {
            overlayImage = overlay
            return
        }
        overlayImage = nil
    }

    func toggleAnnotationsVisible() {
        areAnnotationsVisible.toggle()
    }

    func presentAnnotationEditor() {
        isAnnotationEditorPresented = true
    }

    func presentMarkupEditor() {
        guard canMarkup else { return }
        isMarkupEditorPresented = true
    }

    func markupEditorDidDismiss() {
        isMarkupEditorPresented = false
        refreshOverlayImage()
        if hasVisualAnnotation {
            areAnnotationsVisible = true
        }
    }

    func presentTagsSheet() {
        selectedCollectionIds = Set(screenshot?.collectionIds ?? [])
        selectedTagIds = Set(screenshot?.tagIds ?? [])
        membershipNameEditorMode = nil
        membershipNameDraft = ""
        membershipSheetMode = .tags
    }

    func presentCollectionsSheet() {
        selectedCollectionIds = Set(screenshot?.collectionIds ?? [])
        selectedTagIds = Set(screenshot?.tagIds ?? [])
        membershipNameEditorMode = nil
        membershipNameDraft = ""
        membershipSheetMode = .collections
    }

    func toggleMembershipCollection(_ id: String) {
        if selectedCollectionIds.contains(id) {
            selectedCollectionIds.remove(id)
        } else {
            selectedCollectionIds.insert(id)
        }
    }

    func toggleMembershipTag(_ id: String) {
        if selectedTagIds.contains(id) {
            selectedTagIds.remove(id)
        } else {
            selectedTagIds.insert(id)
        }
    }

    func presentCreateMembershipCollection() {
        membershipNameDraft = ""
        membershipNameEditorMode = .collection
    }

    func presentCreateMembershipTag() {
        membershipNameDraft = ""
        membershipNameEditorMode = .tag
    }

    func saveMembershipNameEditor() async {
        let draft = membershipNameDraft
        guard let mode = membershipNameEditorMode else { return }
        do {
            switch mode {
            case .collection:
                let collection = try await metadataManager.createCollection(name: draft)
                selectedCollectionIds.insert(collection.id)
            case .tag:
                let tag = try await metadataManager.createTag(name: draft)
                selectedTagIds.insert(tag.id)
            }
            membershipNameEditorMode = nil
            membershipNameDraft = ""
        } catch {
            // Keep editor open for empty/invalid names.
        }
    }

    func applyMemberships() async {
        switch membershipSheetMode {
        case .tags:
            try? await metadataManager.setTags(Array(selectedTagIds), forScreenshot: screenshotId)
        case .collections:
            try? await metadataManager.setCollections(Array(selectedCollectionIds), forScreenshot: screenshotId)
        case nil:
            break
        }
        membershipSheetMode = nil
    }

    func presentShare() {
        guard canShare else { return }
        isSharePresented = true
    }

    func presentFullscreen() {
        guard canOpenFullscreen else { return }
        isFullscreenPresented = true
    }

    func presentOCRText() async {
        guard canShowOCRText else { return }
        isOCRTextPresented = true
        didCopyOCRText = false
        ocrLoadError = nil

        if let indexed = screenshot?.ocrText, screenshot?.ocrIndexedAt != nil {
            ocrDisplayText = indexed
            return
        }

        guard let source = image ?? displayedImage else {
            ocrDisplayText = nil
            ocrLoadError = "Photo unavailable"
            return
        }

        isLoadingOCRText = true
        defer { isLoadingOCRText = false }

        do {
            let text = try await ocrService.recognizeText(in: source)
            ocrDisplayText = text
            try? await metadataManager.updateOCRText(screenshotId: screenshotId, text: text)
            print("[Screenbase OCR] copy-sheet screenshotId=\(screenshotId) (\(text.count) chars)")
        } catch {
            ocrDisplayText = nil
            ocrLoadError = error.localizedDescription
            print("[Screenbase OCR] copy-sheet failed screenshotId=\(screenshotId) error=\(error)")
        }
    }

    func copyAllOCRText() {
        let text = (ocrDisplayText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        UIPasteboard.general.string = text
        didCopyOCRText = true
        HapticsManager.instance.mediumImpact()
    }

    /// Removes this screenshot's metadata from Screenbase (does not delete the Photos asset).
    func removeFromLibrary() async {
        try? await metadataManager.deleteScreenshot(id: screenshotId)
    }
}

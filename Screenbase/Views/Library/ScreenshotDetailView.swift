//
//  ScreenshotDetailView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI
import UIKit

struct ScreenshotDetailView: View {
    @Environment(MetadataManager.self) private var metadataManager
    @Environment(PhotosManager.self) private var photosManager
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) private var dismiss

    let screenshotId: String
    @Binding var tabBarVisibility: Visibility

    @State private var viewModel: ScreenshotDetailViewModel?
    @State private var isRemoveConfirmPresented = false

    init(screenshotId: String, tabBarVisibility: Binding<Visibility> = .constant(.hidden)) {
        self.screenshotId = screenshotId
        _tabBarVisibility = tabBarVisibility
    }

    var body: some View {
        Group {
            if let viewModel {
                detailContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .screenbaseBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if let viewModel, viewModel.hasVisualAnnotation {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleAnnotationsVisible()
                    } label: {
                        Text(viewModel.areAnnotationsVisible ? "On" : "Original")
                            .font(ScreenbaseFonts.display(size: 15, weight: .semibold))
                    }
                    .accessibilityLabel(
                        viewModel.areAnnotationsVisible
                            ? "Annotations on, show original"
                            : "Original, show annotations"
                    )
                }
            }
        }
        .onAppear {
            TabBarVisibilityAnimation.set($tabBarVisibility, to: .hidden)
            if viewModel == nil {
                let screen = UIScreen.main.bounds.size
                viewModel = ScreenshotDetailViewModel(
                    screenshotId: screenshotId,
                    metadataManager: metadataManager,
                    photosManager: photosManager,
                    imageTargetSize: CGSize(
                        width: screen.width * displayScale,
                        height: screen.height * displayScale
                    )
                )
            }
        }
        .onDisappear {
            TabBarVisibilityAnimation.set($tabBarVisibility, to: .visible)
        }
        .task(id: screenshotId) {
            await viewModel?.loadImageIfNeeded()
        }
    }

    @ViewBuilder
    private func detailContent(viewModel: ScreenshotDetailViewModel) -> some View {
        if viewModel.screenshot == nil {
            Text("Screenshot unavailable")
                .font(.system(size: 16))
                .foregroundStyle(ScreenbaseColors.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                imageSection(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                actionBar(viewModel: viewModel)
            }
            .ignoresSafeArea(edges: .top)
            .alert("Remove from Library?", isPresented: $isRemoveConfirmPresented) {
                Button("Remove", role: .destructive) {
                    Task {
                        await viewModel.removeFromLibrary()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes Screenbase metadata only. Nothing in Photos is deleted.")
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isAnnotationEditorPresented },
                set: { viewModel.isAnnotationEditorPresented = $0 }
            )) {
                AnnotationNoteSheet(
                    viewModel: AnnotationNoteSheetViewModel(
                        screenshotId: screenshotId,
                        metadataManager: metadataManager,
                        onFinished: {
                            viewModel.isAnnotationEditorPresented = false
                        }
                    ),
                    onDismiss: {
                        viewModel.isAnnotationEditorPresented = false
                    }
                )
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isMembershipSheetPresented },
                set: { viewModel.isMembershipSheetPresented = $0 }
            )) {
                membershipSheet(viewModel: viewModel)
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isSharePresented },
                set: { viewModel.isSharePresented = $0 }
            )) {
                if let image = viewModel.shareImage {
                    ShareActivityView(activityItems: [image])
                        .presentationDetents([.medium, .large])
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.isMarkupEditorPresented },
                set: { presented in
                    if !presented {
                        viewModel.markupEditorDidDismiss()
                    } else {
                        viewModel.isMarkupEditorPresented = true
                    }
                }
            )) {
                if let image = viewModel.image {
                    MarkupEditorView(
                        screenshotId: screenshotId,
                        baseImage: image,
                        metadataManager: metadataManager
                    )
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.isFullscreenPresented },
                set: { viewModel.isFullscreenPresented = $0 }
            )) {
                if let image = viewModel.displayedImage {
                    ScreenshotFullscreenView(image: image) {
                        viewModel.isFullscreenPresented = false
                    }
                }
            }
        }
    }

    private func imageSection(viewModel: ScreenshotDetailViewModel) -> some View {
        Group {
            switch viewModel.imageState {
            case .loading:
                ZStack {
                    ScreenbaseColors.lightGray
                    ProgressView()
                }
            case .missing:
                missingAssetPlaceholder()
            case .loaded:
                if let image = viewModel.displayedImage ?? viewModel.image {
                    Color.black
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.presentFullscreen()
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel("Screenshot")
                        .accessibilityHint("Shows full screen")
                } else {
                    missingAssetPlaceholder()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func missingAssetPlaceholder() -> some View {
        VStack(spacing: 16) {
            Ph.imageBroken.regular
                .color(ScreenbaseColors.gray)
                .frame(width: 40, height: 40)
            Text("Photo unavailable")
                .font(ScreenbaseFonts.display(size: 16, weight: .semibold))
                .foregroundStyle(ScreenbaseColors.ink)
            Text("This screenshot was removed from Photos. Your note, tags, and collections are still saved.")
                .font(.system(size: 14))
                .foregroundStyle(ScreenbaseColors.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Remove from Library") {
                isRemoveConfirmPresented = true
            }
            .buttonStyle(.plain)
            .screenbaseDangerText()
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ScreenbaseColors.lightGray)
    }

    private func actionBar(viewModel: ScreenshotDetailViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ScreenshotDetailActionButton(
                    icon: .noteBlank,
                    title: "Notes",
                    isActive: viewModel.isNotesActionActive
                ) {
                    viewModel.presentAnnotationEditor()
                }

                ScreenshotDetailActionButton(
                    icon: .highlighter,
                    title: "Markup",
                    isActive: viewModel.isMarkupActionActive,
                    isEnabled: viewModel.canMarkup
                ) {
                    viewModel.presentMarkupEditor()
                }

                ScreenshotDetailActionButton(
                    icon: .tag,
                    title: "Tags",
                    isActive: viewModel.isTagsActionActive
                ) {
                    viewModel.presentTagsSheet()
                }

                ScreenshotDetailActionButton(
                    icon: .folderSimple,
                    title: "Collections",
                    isActive: viewModel.isCollectionsActionActive
                ) {
                    viewModel.presentCollectionsSheet()
                }

                ScreenshotDetailActionButton(
                    icon: .export,
                    title: "Share",
                    isActive: viewModel.isShareActionActive,
                    isEnabled: viewModel.canShare
                ) {
                    viewModel.presentShare()
                }
            }
            .padding(.horizontal, ScreenbaseMetrics.edgePadding)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(ScreenbaseColors.background)
    }

    @ViewBuilder
    private func membershipSheet(viewModel: ScreenshotDetailViewModel) -> some View {
        switch viewModel.membershipSheetMode {
        case .tags:
            LibraryAssignSheet(
                title: "Tags",
                collections: [],
                tags: viewModel.allTags,
                selectedCollectionIds: [],
                selectedTagIds: viewModel.selectedTagIds,
                showsCollections: false,
                showsTags: true,
                canApply: true,
                onToggleCollection: { _ in },
                onToggleTag: viewModel.toggleMembershipTag,
                onCreateCollection: {},
                onCreateTag: viewModel.presentCreateMembershipTag,
                onApply: {
                    Task { await viewModel.applyMemberships() }
                },
                onCancel: {
                    viewModel.isMembershipSheetPresented = false
                }
            )
            .alert(
                viewModel.membershipNameEditorTitle,
                isPresented: Binding(
                    get: { viewModel.isMembershipNameEditorPresented },
                    set: { viewModel.isMembershipNameEditorPresented = $0 }
                )
            ) {
                TextField("Name", text: Binding(
                    get: { viewModel.membershipNameDraft },
                    set: { viewModel.membershipNameDraft = $0 }
                ))
                Button("Save") {
                    Task { await viewModel.saveMembershipNameEditor() }
                }
                .disabled(!viewModel.canSaveMembershipName)
                Button("Cancel", role: .cancel) {}
            }
        case .collections:
            LibraryAssignSheet(
                title: "Collections",
                collections: viewModel.allCollections,
                tags: [],
                selectedCollectionIds: viewModel.selectedCollectionIds,
                selectedTagIds: [],
                showsCollections: true,
                showsTags: false,
                canApply: true,
                onToggleCollection: viewModel.toggleMembershipCollection,
                onToggleTag: { _ in },
                onCreateCollection: viewModel.presentCreateMembershipCollection,
                onCreateTag: {},
                onApply: {
                    Task { await viewModel.applyMemberships() }
                },
                onCancel: {
                    viewModel.isMembershipSheetPresented = false
                }
            )
            .alert(
                viewModel.membershipNameEditorTitle,
                isPresented: Binding(
                    get: { viewModel.isMembershipNameEditorPresented },
                    set: { viewModel.isMembershipNameEditorPresented = $0 }
                )
            ) {
                TextField("Name", text: Binding(
                    get: { viewModel.membershipNameDraft },
                    set: { viewModel.membershipNameDraft = $0 }
                ))
                Button("Save") {
                    Task { await viewModel.saveMembershipNameEditor() }
                }
                .disabled(!viewModel.canSaveMembershipName)
                Button("Cancel", role: .cancel) {}
            }
        case nil:
            EmptyView()
        }
    }
}

/// Icon + label action control matching the product’s squircle chip style.
private struct ScreenshotDetailActionButton: View {
    var icon: Ph
    var title: String
    var isActive: Bool = false
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                icon.bold
                    .color(isEnabled ? ScreenbaseColors.ink : ScreenbaseColors.gray)
                    .frame(width: 28, height: 28)
                    .frame(width: 72)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(ScreenbaseColors.lightGray)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(ScreenbaseColors.ink, lineWidth: isActive ? 1.5 : 0)
                    }

                Text(title)
                    .font(ScreenbaseFonts.display(size: 13, weight: isActive ? .bold : .semibold))
                    .foregroundStyle(isEnabled ? ScreenbaseColors.ink : ScreenbaseColors.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

private struct ScreenshotFullscreenView: View {
    var image: UIImage
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }
            .padding(.trailing, 20)
            .padding(.top, 12)
            .accessibilityLabel("Close")
        }
        .statusBarHidden(true)
    }
}

#Preview("Loaded") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    NavigationStack {
        ScreenshotDetailView(screenshotId: ScreenshotRecord.mock.id)
    }
    .environment(metadata)
    .environment(PhotosManager(service: MockPhotosService(
        status: .authorized,
        fullImages: [ScreenshotRecord.mock.assetLocalIdentifier: UIImage(systemName: "photo")!]
    )))
    .task {
        try? await metadata.upsertScreenshot(.mock)
        _ = try? await metadata.createCollection(name: "Onboarding")
        _ = try? await metadata.createTag(name: "bug")
    }
}

#Preview("Missing asset") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    NavigationStack {
        ScreenshotDetailView(screenshotId: ScreenshotRecord.mock.id)
    }
    .environment(metadata)
    .environment(PhotosManager(service: MockPhotosService(
        status: .authorized,
        missingAssetIdentifiers: [ScreenshotRecord.mock.assetLocalIdentifier]
    )))
    .task {
        try? await metadata.upsertScreenshot(.mock)
    }
}

//
//  LibraryView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var appState
    @Environment(MetadataManager.self) private var metadataManager
    @Environment(ScreenshotManager.self) private var screenshotManager
    @Environment(PhotosManager.self) private var photosManager
    @Environment(\.displayScale) private var displayScale

    @State private var viewModel: LibraryViewModel?
    @State private var thumbnailLoader: LibraryThumbnailLoader?
    @State private var navigationPath = NavigationPath()
    @State private var tabBarVisibility: Visibility = .visible
    @State private var openAnnotationOnAppearId: String?

    private let columns = [
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing),
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing),
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel, let thumbnailLoader {
                    libraryContent(viewModel: viewModel, thumbnailLoader: thumbnailLoader)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenbaseBackground()
            .toolbar(.hidden, for: .navigationBar)
            .animatedTabBarVisibility(tabBarVisibility)
            .navigationDestination(for: String.self) { screenshotId in
                ScreenshotDetailView(
                    screenshotId: screenshotId,
                    tabBarVisibility: $tabBarVisibility,
                    openAnnotationOnAppear: openAnnotationOnAppearId == screenshotId
                )
                .onAppear {
                    if openAnnotationOnAppearId == screenshotId {
                        openAnnotationOnAppearId = nil
                    }
                }
            }
        }
        .onAppear {
            TabBarVisibilityAnimation.set($tabBarVisibility, to: .visible)
            if viewModel == nil {
                viewModel = LibraryViewModel(
                    metadataManager: metadataManager,
                    screenshotManager: screenshotManager
                )
            }
            if thumbnailLoader == nil {
                thumbnailLoader = LibraryThumbnailLoader(
                    photosManager: photosManager,
                    scale: displayScale
                )
            }
            consumePendingDeepLinkNavigation()
        }
        .onChange(of: viewModel?.detailScreenshotId) { _, newValue in
            guard let newValue else { return }
            navigationPath.append(newValue)
            viewModel?.clearDetail()
        }
        .onChange(of: appState.pendingDetailScreenshotId) { _, _ in
            consumePendingDeepLinkNavigation()
        }
    }

    private func consumePendingDeepLinkNavigation() {
        guard let id = appState.pendingDetailScreenshotId else { return }
        if appState.pendingAnnotationScreenshotId == id {
            openAnnotationOnAppearId = id
            appState.pendingAnnotationScreenshotId = nil
        }
        appState.pendingDetailScreenshotId = nil
        navigationPath.append(id)
    }

    private func libraryContent(
        viewModel: LibraryViewModel,
        thumbnailLoader: LibraryThumbnailLoader
    ) -> some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                header(viewModel: viewModel)

                LibraryFilterChipRowView(selectedFilter: viewModel.selectedFilter) { filter in
                    viewModel.selectFilter(filter)
                }
                .padding(.bottom, ScreenbaseMetrics.spacing)

                content(for: viewModel, thumbnailLoader: thumbnailLoader)
            }

            VStack {
                Spacer()
                if viewModel.canPresentAssignSheet {
                    selectionToolbar(viewModel: viewModel)
                        .padding(.horizontal, ScreenbaseMetrics.edgePadding)
                        .padding(.bottom, ScreenbaseMetrics.edgePadding)
                } else {
                    LibraryFABView {
                        viewModel.presentAddSheet()
                    }
                    .padding(.trailing, ScreenbaseMetrics.edgePadding)
                    .padding(.bottom, ScreenbaseMetrics.edgePadding)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.isAddSheetPresented },
            set: { viewModel.isAddSheetPresented = $0 }
        )) {
            LibraryAddSourceSheet { source in
                viewModel.isAddSheetPresented = false
                handleAddSource(source)
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.isAssignSheetPresented },
            set: { viewModel.isAssignSheetPresented = $0 }
        )) {
            LibraryAssignSheet(
                collections: viewModel.assignableCollections,
                tags: viewModel.assignableTags,
                selectedCollectionIds: viewModel.selectedAssignCollectionIds,
                selectedTagIds: viewModel.selectedAssignTagIds,
                canApply: viewModel.canApplyAssignment,
                onToggleCollection: viewModel.toggleAssignCollection,
                onToggleTag: viewModel.toggleAssignTag,
                onCreateCollection: viewModel.presentCreateAssignCollection,
                onCreateTag: viewModel.presentCreateAssignTag,
                onApply: {
                    Task { await viewModel.applyAssignment() }
                },
                onCancel: {
                    viewModel.isAssignSheetPresented = false
                }
            )
            .alert(
                viewModel.assignNameEditorTitle,
                isPresented: Binding(
                    get: { viewModel.isAssignNameEditorPresented },
                    set: { viewModel.isAssignNameEditorPresented = $0 }
                )
            ) {
                TextField("Name", text: Binding(
                    get: { viewModel.assignNameDraft },
                    set: { viewModel.assignNameDraft = $0 }
                ))
                Button("Save") {
                    Task { await viewModel.saveAssignNameEditor() }
                }
                .disabled(!viewModel.canSaveAssignName)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func header(viewModel: LibraryViewModel) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Library")
                .displayFont(size: ScreenbaseMetrics.screenTitleSize)
                .foregroundStyle(ScreenbaseColors.ink)

            Spacer()

            Button(viewModel.isSelecting ? "Done" : "Select") {
                HapticsManager.instance.lightImpact()
                viewModel.toggleSelecting()
            }
            .font(ScreenbaseFonts.display(size: 16, weight: .semibold))
            .foregroundStyle(ScreenbaseColors.ink)
        }
        .padding(.horizontal, ScreenbaseMetrics.edgePadding)
        .padding(.top, ScreenbaseMetrics.spacing)
        .padding(.bottom, ScreenbaseMetrics.spacing)
    }

    private func selectionToolbar(viewModel: LibraryViewModel) -> some View {
        HStack(spacing: 12) {
            Text("\(viewModel.selectionCount) selected")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ScreenbaseColors.gray)

            Spacer()

            Button("Assign") {
                HapticsManager.instance.mediumImpact()
                viewModel.presentAssignSheet()
            }
            .buttonStyle(.screenbasePrimary)
            .frame(maxWidth: 160)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: ScreenbaseMetrics.radiusCard, style: .continuous)
                .fill(ScreenbaseColors.elevated)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }

    @ViewBuilder
    private func content(
        for viewModel: LibraryViewModel,
        thumbnailLoader: LibraryThumbnailLoader
    ) -> some View {
        switch viewModel.contentState {
        case .loading:
            grid(
                items: placeholderIds(count: viewModel.skeletonTileCount),
                viewModel: viewModel,
                thumbnailLoader: thumbnailLoader,
                isSkeleton: true
            )
        case .empty:
            emptyState(for: viewModel.selectedFilter)
        case .populated:
            grid(
                items: viewModel.filteredScreenshots.map(\.id),
                viewModel: viewModel,
                thumbnailLoader: thumbnailLoader,
                isSkeleton: false
            )
        }
    }

    private func grid(
        items: [String],
        viewModel: LibraryViewModel,
        thumbnailLoader: LibraryThumbnailLoader,
        isSkeleton: Bool
    ) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: ScreenbaseMetrics.collectionGridSpacing) {
                ForEach(items, id: \.self) { id in
                    if isSkeleton {
                        LibraryScreenshotTileView(
                            assetLocalIdentifier: id,
                            showsPlaceholder: true
                        )
                    } else if let record = metadataManager.screenshots.first(where: { $0.id == id }) {
                        LibraryScreenshotTileView(
                            assetLocalIdentifier: record.assetLocalIdentifier,
                            isSelecting: viewModel.isSelecting,
                            isSelected: viewModel.isSelected(record.id),
                            image: thumbnailLoader.image(for: record.assetLocalIdentifier),
                            onTap: {
                                viewModel.handleTileTap(screenshotId: record.id)
                            },
                            onLongPress: {
                                viewModel.beginSelecting(screenshotId: record.id)
                            }
                        )
                        .onAppear {
                            thumbnailLoader.loadIfNeeded(assetLocalIdentifier: record.assetLocalIdentifier)
                        }
                    }
                }
            }
            .padding(.horizontal, ScreenbaseMetrics.edgePadding)
            .padding(.bottom, viewModel.canPresentAssignSheet ? 110 : 88)
        }
    }

    private func emptyState(for filter: LibraryFilter) -> some View {
        VStack(spacing: 16) {
            Ph.images.bold
                .color(ScreenbaseColors.ink)
                .frame(width: ScreenbaseMetrics.emptyStateIconSize, height: ScreenbaseMetrics.emptyStateIconSize)

            Text(emptyCopy(for: filter))
                .font(.system(size: 16))
                .foregroundStyle(ScreenbaseColors.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyCopy(for filter: LibraryFilter) -> String {
        switch filter {
        case .all:
            "Screenshots from Photos will show up here."
        case .collections:
            "No screenshots in collections yet."
        case .favorites:
            "No favorite screenshots yet."
        case .recent:
            "No screenshots from the last 7 days."
        }
    }

    private func placeholderIds(count: Int) -> [String] {
        (0..<count).map { "skeleton-\($0)" }
    }

    private func handleAddSource(_ source: LibraryAddSource) {
        switch source {
        case .camera, .gallery:
            break
        case .screenshotPicker:
            Task {
                await screenshotManager.runInitialScan()
            }
        }
    }
}

#Preview("Empty") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    LibraryView()
        .environment(metadata)
        .environment(ScreenshotManager(service: MockScreenshotService(screenshots: []), index: metadata))
        .environment(PhotosManager(service: MockPhotosService(status: .authorized, screenshotCount: 0)))
}

#Preview("Populated") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    let screenshots = DiscoveredScreenshot.mocks
    LibraryView()
        .environment(metadata)
        .environment(ScreenshotManager(service: MockScreenshotService(screenshots: screenshots), index: metadata))
        .environment(PhotosManager(service: MockPhotosService(status: .authorized, screenshotCount: screenshots.count)))
        .task {
            try? await metadata.indexNewScreenshots(screenshots)
        }
}

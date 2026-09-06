//
//  CollectionDetailView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI

struct CollectionDetailView: View {
    @Environment(MetadataManager.self) private var metadataManager
    @Environment(PhotosManager.self) private var photosManager
    @Environment(\.displayScale) private var displayScale

    let collectionId: String
    var onOpenScreenshot: (String) -> Void

    @State private var viewModel: CollectionDetailViewModel?
    @State private var thumbnailLoader: LibraryThumbnailLoader?

    private let columns = [
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing),
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing),
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing)
    ]

    var body: some View {
        Group {
            if let viewModel, let thumbnailLoader {
                content(viewModel: viewModel, thumbnailLoader: thumbnailLoader)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .screenbaseBackground()
        .pushedScreen(title: viewModel?.title ?? "Collection")
        .onAppear {
            if viewModel == nil {
                viewModel = CollectionDetailViewModel(
                    collectionId: collectionId,
                    metadataManager: metadataManager
                )
            }
            if thumbnailLoader == nil {
                thumbnailLoader = LibraryThumbnailLoader(
                    photosManager: photosManager,
                    scale: displayScale
                )
            }
        }
        .onChange(of: viewModel?.detailScreenshotId) { _, newValue in
            guard let newValue else { return }
            onOpenScreenshot(newValue)
            viewModel?.clearDetail()
        }
    }

    @ViewBuilder
    private func content(
        viewModel: CollectionDetailViewModel,
        thumbnailLoader: LibraryThumbnailLoader
    ) -> some View {
        if viewModel.collection == nil {
            Text("Collection unavailable")
                .font(.system(size: 16))
                .foregroundStyle(ScreenbaseColors.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch viewModel.contentState {
            case .empty:
                emptyState
            case .populated:
                grid(viewModel: viewModel, thumbnailLoader: thumbnailLoader)
            }
        }
    }

    private func grid(
        viewModel: CollectionDetailViewModel,
        thumbnailLoader: LibraryThumbnailLoader
    ) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: ScreenbaseMetrics.collectionGridSpacing) {
                ForEach(viewModel.screenshots) { record in
                    LibraryScreenshotTileView(
                        assetLocalIdentifier: record.assetLocalIdentifier,
                        image: thumbnailLoader.image(for: record.assetLocalIdentifier),
                        isMissing: thumbnailLoader.isMissing(assetLocalIdentifier: record.assetLocalIdentifier),
                        onTap: {
                            viewModel.handleTileTap(screenshotId: record.id)
                        }
                    )
                    .onAppear {
                        thumbnailLoader.loadIfNeeded(assetLocalIdentifier: record.assetLocalIdentifier)
                    }
                }
            }
            .padding(.horizontal, ScreenbaseMetrics.edgePadding)
            .padding(.bottom, ScreenbaseMetrics.edgePadding)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Ph.images.bold
                .color(ScreenbaseColors.ink)
                .frame(width: ScreenbaseMetrics.emptyStateIconSize, height: ScreenbaseMetrics.emptyStateIconSize)

            Text("No screenshots in this collection yet.")
                .font(.system(size: 16))
                .foregroundStyle(ScreenbaseColors.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Empty") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    NavigationStack {
        CollectionDetailView(collectionId: CollectionRecord.mock.id) { _ in }
    }
    .environment(metadata)
    .environment(PhotosManager(service: MockPhotosService(status: .authorized, screenshotCount: 0)))
    .task {
        _ = try? await metadata.createCollection(name: "Onboarding")
        // Preview uses mock id; seed a matching collection if create used a random id.
    }
}

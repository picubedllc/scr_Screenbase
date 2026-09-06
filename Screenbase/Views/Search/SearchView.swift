//
//  SearchView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI

struct SearchView: View {
    @Environment(MetadataManager.self) private var metadataManager
    @Environment(PhotosManager.self) private var photosManager
    @Environment(\.isSearching) private var isSearching
    @Environment(\.displayScale) private var displayScale

    var query: String = ""

    @State private var viewModel: SearchViewModel?
    @State private var thumbnailLoader: LibraryThumbnailLoader?
    @State private var navigationPath = NavigationPath()
    @State private var tabBarVisibility: Visibility = .visible

    private let columns = [
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing),
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing),
        GridItem(.flexible(), spacing: ScreenbaseMetrics.collectionGridSpacing)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel, let thumbnailLoader {
                    searchContent(viewModel: viewModel, thumbnailLoader: thumbnailLoader)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .screenTitle("Search")
            .toolbar(removing: .search)
            .screenbaseBackground()
            .animatedTabBarVisibility(tabBarVisibility)
            .navigationDestination(for: String.self) { screenshotId in
                ScreenshotDetailView(
                    screenshotId: screenshotId,
                    tabBarVisibility: $tabBarVisibility
                )
            }
        }
        .onAppear {
            TabBarVisibilityAnimation.set($tabBarVisibility, to: .visible)
            if viewModel == nil {
                viewModel = SearchViewModel(metadataManager: metadataManager)
            }
            if thumbnailLoader == nil {
                thumbnailLoader = LibraryThumbnailLoader(
                    photosManager: photosManager,
                    scale: displayScale
                )
            }
            viewModel?.query = query
            viewModel?.setSearching(isSearching)
        }
        .onChange(of: query) { _, newValue in
            viewModel?.query = newValue
        }
        .onChange(of: isSearching) { _, newValue in
            viewModel?.setSearching(newValue)
        }
        .onChange(of: viewModel?.detailScreenshotId) { _, newValue in
            guard let newValue else { return }
            navigationPath.append(newValue)
            viewModel?.clearDetail()
        }
        .onSubmit(of: .search) {
            viewModel?.commitSearch()
        }
    }

    @ViewBuilder
    private func searchContent(
        viewModel: SearchViewModel,
        thumbnailLoader: LibraryThumbnailLoader
    ) -> some View {
        switch viewModel.contentState {
        case .landing:
            landingState
        case .recent:
            recentState(viewModel: viewModel)
        case .emptyResults:
            ContentUnavailableView.search(text: viewModel.query)
        case .results:
            resultsGrid(viewModel: viewModel, thumbnailLoader: thumbnailLoader)
        }
    }

    private var landingState: some View {
        VStack(spacing: 16) {
            Ph.magnifyingGlass.bold
                .color(ScreenbaseColors.ink)
                .frame(
                    width: ScreenbaseMetrics.emptyStateIconSize,
                    height: ScreenbaseMetrics.emptyStateIconSize
                )

            Text("Search across screenshot text, notes, tags, and collections.")
                .font(.system(size: 16))
                .foregroundStyle(ScreenbaseColors.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func recentState(viewModel: SearchViewModel) -> some View {
        Group {
            if viewModel.recentQueries.isEmpty {
                ContentUnavailableView(
                    "No Recent Searches",
                    systemImage: "magnifyingglass",
                    description: Text("Your recent searches will appear here.")
                )
            } else {
                List {
                    Section {
                        ForEach(viewModel.recentQueries, id: \.self) { recent in
                            Button {
                                viewModel.selectRecent(recent)
                            } label: {
                                Label(recent, systemImage: "clock.arrow.circlepath")
                                    .foregroundStyle(ScreenbaseColors.ink)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Recent")
                            Spacer()
                            Button("Clear") {
                                viewModel.clearRecent()
                            }
                            .font(.system(size: 13, weight: .medium))
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func resultsGrid(
        viewModel: SearchViewModel,
        thumbnailLoader: LibraryThumbnailLoader
    ) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: ScreenbaseMetrics.collectionGridSpacing) {
                ForEach(viewModel.results) { item in
                    LibraryScreenshotTileView(
                        assetLocalIdentifier: item.assetLocalIdentifier,
                        image: thumbnailLoader.image(for: item.assetLocalIdentifier),
                        showsPlaceholder: thumbnailLoader.image(for: item.assetLocalIdentifier) == nil
                    ) {
                        viewModel.openDetail(id: item.id)
                    }
                    .task(id: item.assetLocalIdentifier) {
                        thumbnailLoader.loadIfNeeded(assetLocalIdentifier: item.assetLocalIdentifier)
                    }
                }
            }
            .padding(.horizontal, ScreenbaseMetrics.edgePadding)
            .padding(.vertical, ScreenbaseMetrics.spacing)
        }
    }
}

#Preview("Landing") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    SearchView()
        .environment(metadata)
        .environment(PhotosManager(service: MockPhotosService(status: .authorized)))
}

#Preview("Query") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    SearchView(query: "receipts")
        .environment(metadata)
        .environment(PhotosManager(service: MockPhotosService(status: .authorized)))
}

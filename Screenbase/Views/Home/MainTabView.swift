//
//  MainTabView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI

struct MainTabView: View {
    @Environment(MetadataManager.self) private var metadataManager
    @Environment(ScreenshotManager.self) private var screenshotManager

    @State private var selectedTab: Destination = .library
    @State private var searchText = ""
    @State private var captureAnnotationScreenshotId: String?
    @State private var captureAnnotationViewModel: AnnotationNoteSheetViewModel?

    enum Destination: Hashable {
        case library
        case search
        case collections
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .library) {
                LibraryView()
            } label: {
                Label {
                    Text("Library")
                } icon: {
                    Ph.squaresFour.tabBarImage(isSelected: selectedTab == .library)
                }
            }

            Tab(value: .collections) {
                CollectionsView()
            } label: {
                Label {
                    Text("Collections")
                } icon: {
                    Ph.folderSimple.tabBarImage(isSelected: selectedTab == .collections)
                }
            }

            Tab(value: .settings) {
                SettingsView()
            } label: {
                Label {
                    Text("Settings")
                } icon: {
                    Ph.gearSix.tabBarImage(isSelected: selectedTab == .settings)
                }
            }

            Tab(value: .search, role: .search) {
                SearchView(query: searchText)
                    .searchable(text: $searchText, prompt: "Screenbase")
            } label: {
                Label {
                    Text("Search")
                } icon: {
                    Ph.magnifyingGlass.tabBarImage(isSelected: selectedTab == .search)
                }
            }
        }
        .tint(ScreenbaseColors.ink)
        .sheet(
            isPresented: Binding(
                get: { captureAnnotationViewModel != nil },
                set: { presented in
                    if !presented {
                        finishCaptureAnnotation(id: captureAnnotationScreenshotId)
                    }
                }
            )
        ) {
            if let captureAnnotationViewModel {
                AnnotationNoteSheet(
                    viewModel: captureAnnotationViewModel,
                    onDismiss: {
                        finishCaptureAnnotation(id: captureAnnotationScreenshotId)
                    }
                )
            }
        }
        .onChange(of: screenshotManager.pendingCaptureAnnotationIds) { _, ids in
            presentNextCaptureAnnotationIfNeeded(ids: ids)
        }
        .onAppear {
            presentNextCaptureAnnotationIfNeeded(ids: screenshotManager.pendingCaptureAnnotationIds)
        }
    }

    private func presentNextCaptureAnnotationIfNeeded(ids: [String]) {
        guard captureAnnotationViewModel == nil, let nextId = ids.first else { return }
        guard metadataManager.screenshots.contains(where: { $0.id == nextId }) else {
            screenshotManager.acknowledgeCaptureAnnotation(id: nextId)
            presentNextCaptureAnnotationIfNeeded(ids: screenshotManager.pendingCaptureAnnotationIds)
            return
        }

        captureAnnotationScreenshotId = nextId
        captureAnnotationViewModel = AnnotationNoteSheetViewModel(
            screenshotId: nextId,
            metadataManager: metadataManager,
            title: "Add a note",
            allowsSkip: true,
            onFinished: {
                finishCaptureAnnotation(id: nextId)
            }
        )
    }

    private func finishCaptureAnnotation(id: String?) {
        guard let id else {
            captureAnnotationViewModel = nil
            captureAnnotationScreenshotId = nil
            return
        }
        guard captureAnnotationScreenshotId == id || captureAnnotationViewModel != nil else { return }

        captureAnnotationViewModel = nil
        captureAnnotationScreenshotId = nil
        screenshotManager.acknowledgeCaptureAnnotation(id: id)
        presentNextCaptureAnnotationIfNeeded(ids: screenshotManager.pendingCaptureAnnotationIds)
    }
}

#Preview {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    MainTabView()
        .environment(AppState(showMainApp: true))
        .environment(AuthManager(service: AuthServiceMock()))
        .environment(UserManager(services: MockUserServices()))
        .environment(PhotosManager(service: MockPhotosService(status: .authorized, screenshotCount: 24)))
        .environment(PurchaseManager(service: MockPurchaseService()))
        .environment(metadata)
        .environment(ScreenshotManager(service: MockScreenshotService(), index: metadata))
}

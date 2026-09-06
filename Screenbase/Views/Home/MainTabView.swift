//
//  MainTabView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(MetadataManager.self) private var metadataManager
    @Environment(ScreenshotManager.self) private var screenshotManager

    @State private var searchText = ""
    @State private var captureAnnotationScreenshotId: String?
    @State private var captureAnnotationViewModel: AnnotationNoteSheetViewModel?

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            Tab(value: AppState.MainTab.library) {
                LibraryView()
            } label: {
                Label {
                    Text("Library")
                } icon: {
                    Ph.squaresFour.tabBarImage(isSelected: appState.selectedTab == .library)
                }
            }

            Tab(value: AppState.MainTab.collections) {
                CollectionsView()
            } label: {
                Label {
                    Text("Collections")
                } icon: {
                    Ph.folderSimple.tabBarImage(isSelected: appState.selectedTab == .collections)
                }
            }

            Tab(value: AppState.MainTab.settings) {
                SettingsView()
            } label: {
                Label {
                    Text("Settings")
                } icon: {
                    Ph.gearSix.tabBarImage(isSelected: appState.selectedTab == .settings)
                }
            }

            Tab(value: AppState.MainTab.search, role: .search) {
                SearchView(query: searchText)
                    .searchable(text: $searchText, prompt: "Screenbase")
            } label: {
                Label {
                    Text("Search")
                } icon: {
                    Ph.magnifyingGlass.tabBarImage(isSelected: appState.selectedTab == .search)
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
    let deps = AppDependencies.mock
    MainTabView()
        .environment(AppState(showMainApp: true))
        .environment(deps.authManager)
        .environment(deps.userManager)
        .environment(deps.photosManager)
        .environment(deps.purchaseManager)
        .environment(deps.metadataManager)
        .environment(deps.screenshotManager)
        .environment(deps.shareImportManager)
}

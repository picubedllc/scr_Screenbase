//
//  MainTabView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""

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

//
//  AppView.swift
//  Screenbase
//

import SwiftUI

struct AppView: View {
    @Bindable var appState: AppState
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    @Environment(PhotosManager.self) private var photosManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(MetadataManager.self) private var metadataManager
    @Environment(ScreenshotManager.self) private var screenshotManager
    @Environment(ShareImportManager.self) private var shareImportManager

    @AppStorage(SettingsViewModel.Keys.appearance) private var appearance = AppearancePreference.system

    var body: some View {
        AppViewBuilder(showMainApp: appState.showMainApp) {
            MainTabView()
        } onboardingView: {
            ScreenbaseOnboardingView(
                appState: appState,
                photosManager: photosManager,
                screenshotManager: screenshotManager
            )
        }
        .preferredColorScheme(appearance.colorScheme)
        .task {
            await purchaseManager.bootstrap()
            await checkUserStatus()
        }
        .task(id: appState.showMainApp) {
            await startScreenshotDiscoveryIfAuthorized()
            if appState.showMainApp {
                _ = await shareImportManager.importPendingSharedImages()
            }
        }
    }

    private func startScreenshotDiscoveryIfAuthorized() async {
        let status = photosManager.authorizationStatus
        guard status == .authorized || status == .limited else { return }
        await screenshotManager.startDiscovery()
    }

    private func checkUserStatus() async {
        if let user = authManager.auth {
            do {
                try await userManager.login(auth: user, isNewUser: false)
                metadataManager.configure(userId: user.uid)
            } catch {
                try? await Task.sleep(for: .seconds(5))
                await checkUserStatus()
            }
        } else {
            do {
                let result = try await authManager.signInAnonymously()
                try await userManager.login(auth: result.user, isNewUser: result.isNewUser)
                metadataManager.configure(userId: result.user.uid)
            } catch {
                try? await Task.sleep(for: .seconds(5))
                await checkUserStatus()
            }
        }
    }
}

#Preview("Screenbase App — Main") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    let deps = AppDependencies.mock
    AppView(appState: AppState(showMainApp: true))
        .environment(deps.authManager)
        .environment(deps.userManager)
        .environment(deps.photosManager)
        .environment(deps.purchaseManager)
        .environment(deps.metadataManager)
        .environment(deps.screenshotManager)
        .environment(deps.shareImportManager)
}

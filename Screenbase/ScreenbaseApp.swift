//
//  ScreenbaseApp.swift
//  Screenbase
//

import SwiftUI

@main
struct ScreenbaseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppView(appState: appState)
                .environment(appState)
                .environment(delegate.dependencies.authManager)
                .environment(delegate.dependencies.userManager)
                .environment(delegate.dependencies.photosManager)
                .environment(delegate.dependencies.purchaseManager)
                .environment(delegate.dependencies.metadataManager)
                .environment(delegate.dependencies.screenshotManager)
                .environment(delegate.dependencies.shareImportManager)
                .onOpenURL { url in
                    Task { await handleOpenURL(url) }
                }
        }
    }

    @MainActor
    private func handleOpenURL(_ url: URL) async {
        guard let link = DeepLink.parse(url) else { return }
        appState.handleDeepLink(link)

        switch link {
        case .importShared:
            let ids = await delegate.dependencies.shareImportManager.importPendingSharedImages()
            if let first = ids.first {
                appState.pendingDetailScreenshotId = first
            }
        case .annotateLatest:
            let latest = delegate.dependencies.metadataManager.screenshots
                .sorted { ($0.captureDate ?? $0.createdAt) > ($1.captureDate ?? $1.createdAt) }
                .first
            if let latest {
                appState.pendingDetailScreenshotId = latest.id
                appState.pendingAnnotationScreenshotId = latest.id
            }
        case .library, .search:
            break
        }
    }
}

//
//  ScreenbaseApp.swift
//  Screenbase
//

import SwiftUI

@main
struct ScreenbaseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(delegate.dependencies.authManager)
                .environment(delegate.dependencies.userManager)
                .environment(delegate.dependencies.photosManager)
                .environment(delegate.dependencies.purchaseManager)
                .environment(delegate.dependencies.metadataManager)
                .environment(delegate.dependencies.screenshotManager)
                .environment(delegate.dependencies.ocrManager)
        }
    }
}

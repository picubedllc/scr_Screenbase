//
//  ScreenbaseAppIntents.swift
//  Screenbase
//

import AppIntents
import Foundation
import UIKit

struct OpenLibraryIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Library"
    static var description = IntentDescription("Opens your Screenbase screenshot library.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let url = DeepLink.library.url else { return .result() }
        await UIApplication.shared.open(url)
        return .result()
    }
}

struct OpenSearchIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Search"
    static var description = IntentDescription("Opens Screenbase search.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let url = DeepLink.search.url else { return .result() }
        await UIApplication.shared.open(url)
        return .result()
    }
}

struct AnnotateLatestScreenshotIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Note on Latest Screenshot"
    static var description = IntentDescription("Opens a note on your most recent screenshot in Screenbase.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let url = DeepLink.annotateLatest.url else { return .result() }
        await UIApplication.shared.open(url)
        return .result()
    }
}

struct ScreenbaseAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenLibraryIntent(),
            phrases: [
                "Open \(.applicationName) Library",
                "Show my screenshots in \(.applicationName)"
            ],
            shortTitle: "Library",
            systemImageName: "square.grid.2x2"
        )
        AppShortcut(
            intent: OpenSearchIntent(),
            phrases: [
                "Search in \(.applicationName)",
                "Open \(.applicationName) Search"
            ],
            shortTitle: "Search",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: AnnotateLatestScreenshotIntent(),
            phrases: [
                "Add a note to my latest screenshot in \(.applicationName)",
                "Annotate latest screenshot in \(.applicationName)"
            ],
            shortTitle: "Latest note",
            systemImageName: "note.text"
        )
    }
}

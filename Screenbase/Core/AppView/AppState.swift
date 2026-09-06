//
//  AppState.swift
//  Screenbase
//

import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    enum Keys {
        static let showMainApp = "screenbase_showMainApp"
    }

    enum MainTab: Hashable {
        case library
        case search
        case collections
        case settings
    }

    private(set) var showMainApp: Bool {
        didSet {
            UserDefaults.standard.set(showMainApp, forKey: Keys.showMainApp)
        }
    }

    var selectedTab: MainTab = .library
    /// Opens Screenshot Detail for annotate-latest / post-import navigation.
    var pendingDetailScreenshotId: String?
    var pendingAnnotationScreenshotId: String?

    init(showMainApp: Bool = UserDefaults.standard.bool(forKey: Keys.showMainApp)) {
        self.showMainApp = showMainApp
    }

    func updateViewState(showMainApp: Bool) {
        self.showMainApp = showMainApp
    }

    func handleDeepLink(_ link: DeepLink) {
        guard showMainApp else { return }
        switch link {
        case .library:
            selectedTab = .library
        case .search:
            selectedTab = .search
        case .annotateLatest:
            selectedTab = .library
            // Caller resolves latest id after metadata is ready.
        case .importShared:
            selectedTab = .library
        }
    }
}

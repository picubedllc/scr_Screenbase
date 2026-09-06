//
//  SystemSettings.swift
//  Screenbase
//

import UIKit

enum SystemSettings {
    /// Opens the system Settings page for this app (Photos / permissions).
    @MainActor
    static func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

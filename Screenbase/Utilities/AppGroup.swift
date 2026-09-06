//
//  AppGroup.swift
//  Screenbase
//

import Foundation

enum AppGroup {
    static let suiteName = "group.com.getscreenbase.Screenbase"
    static let inboxFolderName = "ShareInbox"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    static var inboxURL: URL? {
        containerURL?.appendingPathComponent(inboxFolderName, isDirectory: true)
    }
}

//
//  ShareInbox.swift
//  Screenbase
//

import Foundation
import UIKit

/// App Group inbox used by the Share Extension → main app handoff.
/// Extension writes JPEG files; the app imports them into permanent storage then clears the inbox.
enum ShareInbox {
    static let fileExtension = "jpg"

    /// Writes image bytes into the App Group inbox. Returns the file URL.
    @discardableResult
    static func writeInboxImage(_ data: Data, id: String = UUID().uuidString) throws -> URL {
        let inbox = try ensureInboxDirectory()
        let url = inbox.appendingPathComponent("\(id).\(fileExtension)")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Lists pending inbox image URLs (sorted by name).
    static func pendingImageURLs() -> [URL] {
        guard let inbox = AppGroup.inboxURL else { return [] }
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: inbox,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return urls
            .filter { $0.pathExtension.lowercased() == fileExtension }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Deletes every file currently in the inbox.
    static func clearInbox() {
        for url in pendingImageURLs() {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func ensureInboxDirectory() throws -> URL {
        guard let inbox = AppGroup.inboxURL else {
            throw ShareInboxError.containerUnavailable
        }
        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        return inbox
    }
}

enum ShareInboxError: Error {
    case containerUnavailable
}

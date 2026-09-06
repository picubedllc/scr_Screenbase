//
//  ShareViewController.swift
//  ScreenbaseShareExtension
//

import UIKit
import UniformTypeIdentifiers

/// Saves shared images into the App Group inbox and opens Screenbase to import them.
final class ShareViewController: UIViewController {
    private let appGroupId = "group.com.getscreenbase.Screenbase"
    private let inboxFolderName = "ShareInbox"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await processSharedItems() }
    }

    private func processSharedItems() async {
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        var saved = 0

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                if let data = await loadImageData(from: provider) {
                    do {
                        try writeInboxImage(data)
                        saved += 1
                    } catch {
                        continue
                    }
                }
            }
        }

        if saved > 0 {
            openHostApp()
        }
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                if let data = item as? Data {
                    continuation.resume(returning: data)
                    return
                }
                if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    continuation.resume(returning: data)
                    return
                }
                if let image = item as? UIImage, let data = image.jpegData(compressionQuality: 0.92) {
                    continuation.resume(returning: data)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    private func writeInboxImage(_ data: Data) throws {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            throw NSError(domain: "ScreenbaseShare", code: 1)
        }
        let inbox = container.appendingPathComponent(inboxFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let url = inbox.appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: url, options: .atomic)
    }

    private func openHostApp() {
        guard let url = URL(string: "screenbase://import-shared") else { return }
        extensionContext?.open(url, completionHandler: nil)
    }
}

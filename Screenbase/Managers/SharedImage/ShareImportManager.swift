//
//  ShareImportManager.swift
//  Screenbase
//

import Foundation
import Observation
import UIKit

/// Drains the Share Extension App Group inbox into permanent shared image storage + metadata.
@MainActor
@Observable
final class ShareImportManager {
    private(set) var lastImportedCount = 0
    private(set) var lastImportedScreenshotIds: [String] = []

    private let sharedImageStore: any SharedImageStore
    private let metadataManager: MetadataManager

    init(sharedImageStore: any SharedImageStore, metadataManager: MetadataManager) {
        self.sharedImageStore = sharedImageStore
        self.metadataManager = metadataManager
    }

    /// Imports all pending inbox images, then clears the App Group inbox.
    @discardableResult
    func importPendingSharedImages() async -> [String] {
        let pending = ShareInbox.pendingImageURLs()
        guard !pending.isEmpty else {
            lastImportedCount = 0
            lastImportedScreenshotIds = []
            return []
        }

        var importedIds: [String] = []
        for fileURL in pending {
            guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else { continue }
            let assetId = SharedAssetID.make()
            do {
                try sharedImageStore.saveImageData(data, assetLocalIdentifier: assetId)
                let record = ScreenshotRecord(
                    id: FirestoreDocumentID.fromAssetLocalIdentifier(assetId),
                    assetLocalIdentifier: assetId,
                    captureDate: Date()
                )
                try await metadataManager.upsertScreenshot(record)
                importedIds.append(record.id)
            } catch {
                continue
            }
        }

        ShareInbox.clearInbox()
        lastImportedCount = importedIds.count
        lastImportedScreenshotIds = importedIds
        return importedIds
    }
}

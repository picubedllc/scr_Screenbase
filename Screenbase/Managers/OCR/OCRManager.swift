//
//  OCRManager.swift
//  Screenbase
//

import Foundation
import Observation
import UIKit

/// Background on-device OCR indexing job. Writes extracted text onto `ScreenshotRecord`.
@MainActor
@Observable
final class OCRManager {
    private let service: any ScreenshotOCRService
    private let metadataManager: MetadataManager
    private let photosManager: PhotosManager

    /// Max pixel dimension for Vision input (keeps indexing fast).
    private let imageTargetSize = CGSize(width: 1_200, height: 1_200)

    private(set) var isIndexing = false
    private(set) var pendingCount = 0
    private(set) var lastIndexedId: String?
    private(set) var lastError: String?

    private var queue: [String] = []
    private var queuedIds: Set<String> = []
    private var isProcessing = false

    init(
        service: any ScreenshotOCRService,
        metadataManager: MetadataManager,
        photosManager: PhotosManager
    ) {
        self.service = service
        self.metadataManager = metadataManager
        self.photosManager = photosManager
    }

    /// Enqueues every local screenshot that has not been OCR-indexed yet.
    func enqueueUnindexedScreenshots() {
        let ids = metadataManager.screenshots
            .filter { $0.ocrIndexedAt == nil }
            .map(\.id)
        enqueue(screenshotIds: ids)
    }

    func enqueue(screenshotIds: [String]) {
        for id in screenshotIds where !queuedIds.contains(id) {
            let record = metadataManager.screenshots.first { $0.id == id }
            guard record?.ocrIndexedAt == nil else { continue }
            queuedIds.insert(id)
            queue.append(id)
        }
        pendingCount = queue.count
        Task { await processQueueIfNeeded() }
    }

    private func processQueueIfNeeded() async {
        guard !isProcessing else { return }
        isProcessing = true
        isIndexing = true
        defer {
            isProcessing = false
            isIndexing = !queue.isEmpty
            pendingCount = queue.count
        }

        while let id = queue.first {
            queue.removeFirst()
            queuedIds.remove(id)
            pendingCount = queue.count
            await indexScreenshot(id: id)
        }
    }

    private func indexScreenshot(id: String) async {
        guard let record = metadataManager.screenshots.first(where: { $0.id == id }) else { return }
        guard record.ocrIndexedAt == nil else { return }

        guard let image = await photosManager.fullImage(
            forAssetLocalIdentifier: record.assetLocalIdentifier,
            targetSize: imageTargetSize
        ) else {
            // Missing Photos asset — mark indexed with empty text so we don't retry forever.
            try? await metadataManager.updateOCRText(screenshotId: id, text: "")
            lastIndexedId = id
            return
        }

        do {
            let text = try await service.recognizeText(in: image)
            try await metadataManager.updateOCRText(screenshotId: id, text: text)
            lastIndexedId = id
            lastError = nil
            print("[Screenbase OCR] indexed \(id) (\(text.count) chars)")
        } catch {
            lastError = error.localizedDescription
            print("[Screenbase OCR] failed \(id): \(error.localizedDescription)")
            // Leave ocrIndexedAt nil so a later pass can retry.
        }
    }
}

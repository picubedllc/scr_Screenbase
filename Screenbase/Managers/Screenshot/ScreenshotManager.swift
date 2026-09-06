//
//  ScreenshotManager.swift
//  Screenbase
//

import Foundation
import Observation

@MainActor
@Observable
final class ScreenshotManager {
    private let service: any ScreenshotService
    private let index: any ScreenshotIndexing

    private(set) var discoveredScreenshots: [DiscoveredScreenshot] = []
    private(set) var lastIndexedCount = 0
    private(set) var isScanning = false
    private(set) var isObserving = false
    private(set) var lastError: ScreenshotServiceError?
    /// Screenshot record IDs waiting for the capture-time annotation prompt (post-initial scan only).
    private(set) var pendingCaptureAnnotationIds: [String] = []

    private var observationTask: Task<Void, Never>?
    private var shouldPromptForNewCaptures = false

    init(service: any ScreenshotService, index: any ScreenshotIndexing) {
        self.service = service
        self.index = index
    }

    /// Backfills every screenshot already on device, then starts the library observer.
    func startDiscovery() async {
        await runInitialScan()
        shouldPromptForNewCaptures = true
        startObservingLibraryChanges()
    }

    func stopDiscovery() {
        observationTask?.cancel()
        observationTask = nil
        isObserving = false
    }

    /// Scans all screenshot assets and indexes ones not already known.
    @discardableResult
    func runInitialScan() async -> [DiscoveredScreenshot] {
        await scanAndIndexNewScreenshots(promptForCaptures: false)
    }

    func acknowledgeCaptureAnnotation(id: String) {
        pendingCaptureAnnotationIds.removeAll { $0 == id }
    }

    private func startObservingLibraryChanges() {
        guard observationTask == nil else { return }
        isObserving = true

        observationTask = Task { [weak self] in
            guard let self else { return }
            for await _ in service.libraryChangeEvents() {
                guard !Task.isCancelled else { break }
                _ = await scanAndIndexNewScreenshots(promptForCaptures: shouldPromptForNewCaptures)
            }
            isObserving = false
        }
    }

    @discardableResult
    private func scanAndIndexNewScreenshots(promptForCaptures: Bool) async -> [DiscoveredScreenshot] {
        isScanning = true
        defer { isScanning = false }

        do {
            let allScreenshots = try await service.fetchScreenshots()
            discoveredScreenshots = allScreenshots
            lastError = nil

            let known = index.indexedAssetIdentifiers
            let newcomers = allScreenshots.filter { !known.contains($0.assetLocalIdentifier) }
            guard !newcomers.isEmpty else {
                lastIndexedCount = 0
                return []
            }

            try await index.indexNewScreenshots(newcomers)
            lastIndexedCount = newcomers.count

            if promptForCaptures {
                let ids = newcomers.map {
                    FirestoreDocumentID.fromAssetLocalIdentifier($0.assetLocalIdentifier)
                }
                for id in ids where !pendingCaptureAnnotationIds.contains(id) {
                    pendingCaptureAnnotationIds.append(id)
                }
            }

            return newcomers
        } catch let error as ScreenshotServiceError {
            lastError = error
            lastIndexedCount = 0
            return []
        } catch {
            lastError = .notAuthorized
            lastIndexedCount = 0
            return []
        }
    }
}

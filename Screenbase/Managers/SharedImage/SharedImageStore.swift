//
//  SharedImageStore.swift
//  Screenbase
//

import Foundation
import UIKit

/// Permanent on-device store for images shared into Screenbase (not Photos assets).
protocol SharedImageStore: Sendable {
    func saveImageData(_ data: Data, assetLocalIdentifier: String) throws
    func loadImage(assetLocalIdentifier: String) -> UIImage?
    func deleteImage(assetLocalIdentifier: String) throws
    func hasImage(assetLocalIdentifier: String) -> Bool
}

enum SharedAssetID {
    static let prefix = "shared/"

    static func make() -> String {
        "\(prefix)\(UUID().uuidString)"
    }

    static func isShared(_ assetLocalIdentifier: String) -> Bool {
        assetLocalIdentifier.hasPrefix(prefix)
    }

    static func fileName(for assetLocalIdentifier: String) -> String {
        assetLocalIdentifier
            .replacingOccurrences(of: "/", with: "__")
            .appending(".jpg")
    }
}

final class FileSharedImageStore: SharedImageStore, @unchecked Sendable {
    private let directory: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        directory = base.appendingPathComponent("Screenbase/shared_images", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func saveImageData(_ data: Data, assetLocalIdentifier: String) throws {
        let url = directory.appendingPathComponent(SharedAssetID.fileName(for: assetLocalIdentifier))
        try data.write(to: url, options: .atomic)
    }

    func loadImage(assetLocalIdentifier: String) -> UIImage? {
        let url = directory.appendingPathComponent(SharedAssetID.fileName(for: assetLocalIdentifier))
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(assetLocalIdentifier: String) throws {
        let url = directory.appendingPathComponent(SharedAssetID.fileName(for: assetLocalIdentifier))
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    func hasImage(assetLocalIdentifier: String) -> Bool {
        let url = directory.appendingPathComponent(SharedAssetID.fileName(for: assetLocalIdentifier))
        return fileManager.fileExists(atPath: url.path)
    }
}

final class InMemorySharedImageStore: SharedImageStore, @unchecked Sendable {
    private var images: [String: Data] = [:]

    func saveImageData(_ data: Data, assetLocalIdentifier: String) throws {
        images[assetLocalIdentifier] = data
    }

    func loadImage(assetLocalIdentifier: String) -> UIImage? {
        guard let data = images[assetLocalIdentifier] else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(assetLocalIdentifier: String) throws {
        images.removeValue(forKey: assetLocalIdentifier)
    }

    func hasImage(assetLocalIdentifier: String) -> Bool {
        images[assetLocalIdentifier] != nil
    }
}

//
//  FileAnnotationDrawingStore.swift
//  Screenbase
//

import Foundation

/// Persists PKDrawing data under Application Support/Screenbase/drawings.
struct FileAnnotationDrawingStore: AnnotationDrawingStore {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadDrawing(screenshotId: String) -> Data? {
        guard let url = try? fileURL(for: screenshotId) else { return nil }
        return try? Data(contentsOf: url)
    }

    func saveDrawing(screenshotId: String, data: Data) throws {
        let url = try fileURL(for: screenshotId)
        try data.write(to: url, options: .atomic)
    }

    func deleteDrawing(screenshotId: String) throws {
        let url = try fileURL(for: screenshotId)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private func drawingsDirectoryURL() throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base
            .appendingPathComponent("Screenbase", isDirectory: true)
            .appendingPathComponent("drawings", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func fileURL(for screenshotId: String) throws -> URL {
        let safeName = screenshotId.replacingOccurrences(of: "/", with: "__")
        return try drawingsDirectoryURL().appendingPathComponent("\(safeName).drawing")
    }
}

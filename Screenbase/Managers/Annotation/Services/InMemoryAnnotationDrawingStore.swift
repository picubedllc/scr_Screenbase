//
//  InMemoryAnnotationDrawingStore.swift
//  Screenbase
//

import Foundation

/// In-memory drawing store for previews and unit tests.
@MainActor
final class InMemoryAnnotationDrawingStore: AnnotationDrawingStore {
    private var drawings: [String: Data] = [:]

    func loadDrawing(screenshotId: String) -> Data? {
        drawings[screenshotId]
    }

    func saveDrawing(screenshotId: String, data: Data) throws {
        drawings[screenshotId] = data
    }

    func deleteDrawing(screenshotId: String) throws {
        drawings.removeValue(forKey: screenshotId)
    }
}

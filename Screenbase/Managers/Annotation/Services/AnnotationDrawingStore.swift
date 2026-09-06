//
//  AnnotationDrawingStore.swift
//  Screenbase
//

import Foundation

/// Local persistence for editable PencilKit drawing bytes.
@MainActor
protocol AnnotationDrawingStore {
    func loadDrawing(screenshotId: String) -> Data?
    func saveDrawing(screenshotId: String, data: Data) throws
    func deleteDrawing(screenshotId: String) throws
}

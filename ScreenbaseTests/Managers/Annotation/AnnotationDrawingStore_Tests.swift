//
//  AnnotationDrawingStore_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing

@Suite("AnnotationDrawingStore Tests")
struct AnnotationDrawingStore_Tests {
    @Test("In-memory store round-trips drawing data")
    @MainActor
    func inMemoryRoundTrip() throws {
        let store = InMemoryAnnotationDrawingStore()
        let payload = Data("pk-drawing".utf8)

        try store.saveDrawing(screenshotId: "shot_1", data: payload)

        #expect(store.loadDrawing(screenshotId: "shot_1") == payload)

        try store.deleteDrawing(screenshotId: "shot_1")
        #expect(store.loadDrawing(screenshotId: "shot_1") == nil)
    }
}

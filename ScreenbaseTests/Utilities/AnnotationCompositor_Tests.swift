//
//  AnnotationCompositor_Tests.swift
//  ScreenbaseTests
//

import Foundation
import PencilKit
@testable import Screenbase
import Testing
import UIKit

@Suite("AnnotationCompositor Tests")
struct AnnotationCompositor_Tests {
    @Test("Composite without overlay returns the base image")
    @MainActor
    func compositeWithoutOverlayReturnsBase() {
        let base = UIImage(systemName: "photo")!
        let result = AnnotationCompositor.composite(base: base, overlay: nil)
        #expect(result.size == base.size)
    }

    @Test("Empty drawing still produces an overlay canvas image")
    @MainActor
    func emptyDrawingProducesOverlayImage() throws {
        let drawing = PKDrawing()
        let data = drawing.dataRepresentation()
        let overlay = try #require(
            AnnotationCompositor.overlayImage(
                from: data,
                canvasSize: CGSize(width: 100, height: 200),
                scale: 2
            )
        )
        #expect(overlay.size.width == 100)
        #expect(overlay.size.height == 200)
    }

    @Test("Invalid drawing data returns nil overlay")
    @MainActor
    func invalidDrawingDataReturnsNil() {
        let overlay = AnnotationCompositor.overlayImage(
            from: Data("not-a-drawing".utf8),
            canvasSize: CGSize(width: 10, height: 10),
            scale: 1
        )
        #expect(overlay == nil)
    }
}

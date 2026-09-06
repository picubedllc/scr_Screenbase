//
//  AnnotationCompositor.swift
//  Screenbase
//

import CoreGraphics
import Foundation
import PencilKit
import UIKit

enum AnnotationCompositor {
    /// Renders a transparent overlay image from a PencilKit drawing.
    static func overlayImage(
        from drawingData: Data,
        canvasSize: CGSize,
        scale: CGFloat
    ) -> UIImage? {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return nil }
        guard let drawing = try? PKDrawing(data: drawingData) else { return nil }
        let bounds = CGRect(origin: .zero, size: canvasSize)
        return drawing.image(from: bounds, scale: scale)
    }

    /// Composites the base screenshot with an annotation overlay (same size).
    static func composite(base: UIImage, overlay: UIImage?) -> UIImage {
        guard let overlay else { return base }
        let size = base.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = base.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
            overlay.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

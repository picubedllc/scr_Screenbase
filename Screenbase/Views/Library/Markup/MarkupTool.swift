//
//  MarkupTool.swift
//  Screenbase
//

import PencilKit
import PhosphorSwift
import SwiftUI

/// Native PencilKit tools exposed in the Markup editor tray.
enum MarkupTool: String, CaseIterable, Identifiable, Sendable {
    case pen
    case pencil
    case marker
    case monoline
    case fountainPen
    case watercolor
    case crayon
    case reed
    case eraser
    case lasso

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .pen: "Pen"
        case .pencil: "Pencil"
        case .marker: "Highlighter"
        case .monoline: "Monoline"
        case .fountainPen: "Fountain"
        case .watercolor: "Watercolor"
        case .crayon: "Crayon"
        case .reed: "Reed"
        case .eraser: "Eraser"
        case .lasso: "Lasso"
        }
    }

    var icon: Ph {
        switch self {
        case .pen: .pen
        case .pencil: .pencil
        case .marker: .highlighter
        case .monoline: .lineSegment
        case .fountainPen: .penNib
        case .watercolor: .paintBrush
        case .crayon: .paintBrushBroad
        case .reed: .plant
        case .eraser: .eraser
        case .lasso: .lasso
        }
    }

    var usesColor: Bool {
        switch self {
        case .eraser, .lasso: false
        default: true
        }
    }

    /// Default stroke width tuned per tool; lasso ignores width.
    var defaultWidth: CGFloat {
        switch self {
        case .pen: 5
        case .pencil: 4
        case .marker: 28
        case .monoline: 6
        case .fountainPen: 8
        case .watercolor: 20
        case .crayon: 14
        case .reed: 7
        case .eraser: 24
        case .lasso: 0
        }
    }

    func makePKTool(color: UIColor, width: CGFloat) -> PKTool {
        switch self {
        case .pen:
            PKInkingTool(.pen, color: color, width: width)
        case .pencil:
            PKInkingTool(.pencil, color: color, width: width)
        case .marker:
            PKInkingTool(.marker, color: color, width: width)
        case .monoline:
            PKInkingTool(.monoline, color: color, width: width)
        case .fountainPen:
            PKInkingTool(.fountainPen, color: color, width: width)
        case .watercolor:
            PKInkingTool(.watercolor, color: color, width: width)
        case .crayon:
            PKInkingTool(.crayon, color: color, width: width)
        case .reed:
            PKInkingTool(.reed, color: color, width: width)
        case .eraser:
            PKEraserTool(.bitmap, width: width)
        case .lasso:
            PKLassoTool()
        }
    }
}

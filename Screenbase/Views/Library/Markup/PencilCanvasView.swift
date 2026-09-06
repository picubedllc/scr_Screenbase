//
//  PencilCanvasView.swift
//  Screenbase
//

import PencilKit
import SwiftUI
import UIKit

/// Transparent PencilKit canvas for annotation overlays.
struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var inkColor: UIColor
    var inkWidth: CGFloat
    var allowsDrawing: Bool
    var onUndoManagerChange: ((UndoManager?) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.overrideUserInterfaceStyle = .light
        canvas.drawingPolicy = .anyInput
        canvas.isScrollEnabled = false
        canvas.tool = PKInkingTool(.marker, color: inkColor, width: inkWidth)
        canvas.isUserInteractionEnabled = allowsDrawing
        context.coordinator.observeUndoManager(of: canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
        let tool = PKInkingTool(.marker, color: inkColor, width: inkWidth)
        if let current = canvas.tool as? PKInkingTool,
           current.inkType == tool.inkType,
           current.color == tool.color,
           abs(current.width - tool.width) < 0.1
        {
            // Keep existing tool instance when unchanged.
        } else {
            canvas.tool = tool
        }
        canvas.isUserInteractionEnabled = allowsDrawing
        context.coordinator.observeUndoManager(of: canvas)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasView
        private weak var observedUndoManager: UndoManager?
        private var undoObserver: NSObjectProtocol?
        private var redoObserver: NSObjectProtocol?

        init(_ parent: PencilCanvasView) {
            self.parent = parent
        }

        deinit {
            clearUndoObservers()
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onUndoManagerChange?(canvasView.undoManager)
        }

        func observeUndoManager(of canvas: PKCanvasView) {
            let manager = canvas.undoManager
            parent.onUndoManagerChange?(manager)
            guard observedUndoManager !== manager else { return }
            clearUndoObservers()
            observedUndoManager = manager
            guard let manager else { return }

            let center = NotificationCenter.default
            undoObserver = center.addObserver(
                forName: .NSUndoManagerDidUndoChange,
                object: manager,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                parent.onUndoManagerChange?(manager)
            }
            redoObserver = center.addObserver(
                forName: .NSUndoManagerDidRedoChange,
                object: manager,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                parent.onUndoManagerChange?(manager)
            }
        }

        private func clearUndoObservers() {
            let center = NotificationCenter.default
            if let undoObserver {
                center.removeObserver(undoObserver)
            }
            if let redoObserver {
                center.removeObserver(redoObserver)
            }
            undoObserver = nil
            redoObserver = nil
            observedUndoManager = nil
        }
    }
}

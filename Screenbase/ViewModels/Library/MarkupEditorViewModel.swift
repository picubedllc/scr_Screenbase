//
//  MarkupEditorViewModel.swift
//  Screenbase
//

import Foundation
import Observation
import PencilKit
import SwiftUI
import UIKit

@MainActor
@Observable
final class MarkupEditorViewModel {
    let screenshotId: String
    let baseImage: UIImage

    var drawing = PKDrawing()
    var selectedTool: MarkupTool = .marker
    var inkColor: Color = .yellow
    var isSaving = false
    var saveWarning: String?
    var canUndo = false
    var canRedo = false

    private let metadataManager: MetadataManager
    private weak var undoManager: UndoManager?
    private var widthsByTool: [MarkupTool: CGFloat] = [:]

    init(screenshotId: String, baseImage: UIImage, metadataManager: MetadataManager) {
        self.screenshotId = screenshotId
        self.baseImage = baseImage
        self.metadataManager = metadataManager
        for tool in MarkupTool.allCases {
            widthsByTool[tool] = tool.defaultWidth
        }
        if let data = metadataManager.loadDrawingData(screenshotId: screenshotId),
           let existing = try? PKDrawing(data: data)
        {
            drawing = existing
        }
    }

    var inkUIColor: UIColor {
        UIColor(inkColor)
    }

    var inkWidth: CGFloat {
        get { widthsByTool[selectedTool] ?? selectedTool.defaultWidth }
        set { widthsByTool[selectedTool] = newValue }
    }

    var showsColorPicker: Bool {
        selectedTool.usesColor
    }

    var pkTool: PKTool {
        selectedTool.makePKTool(color: inkUIColor, width: inkWidth)
    }

    func selectTool(_ tool: MarkupTool) {
        selectedTool = tool
    }

    func bindUndoManager(_ manager: UndoManager?) {
        undoManager = manager
        refreshUndoState()
    }

    func undo() {
        undoManager?.undo()
        refreshUndoState()
    }

    func redo() {
        undoManager?.redo()
        refreshUndoState()
    }

    func refreshUndoState() {
        canUndo = undoManager?.canUndo ?? false
        canRedo = undoManager?.canRedo ?? false
    }

    /// Persists drawing locally, uploads overlay, updates metadata. Returns `true` when done should dismiss.
    func save() async -> Bool {
        isSaving = true
        saveWarning = nil
        defer { isSaving = false }

        let canvasSize = baseImage.size
        let drawingData = drawing.dataRepresentation()
        guard let overlay = AnnotationCompositor.overlayImage(
            from: drawingData,
            canvasSize: canvasSize,
            scale: baseImage.scale
        ) else {
            saveWarning = "Couldn't render annotation."
            return false
        }

        do {
            let uploaded = try await metadataManager.saveVisualAnnotation(
                screenshotId: screenshotId,
                drawingData: drawingData,
                overlayImage: overlay
            )
            if !uploaded {
                saveWarning = metadataManager.lastVisualAnnotationUploadError
                    ?? "Annotation saved on device, but cloud upload failed."
                // Keep editor open so the warning alert can present, then dismiss from the alert.
                return false
            }
            return true
        } catch {
            saveWarning = "Couldn't save annotation."
            return false
        }
    }
}

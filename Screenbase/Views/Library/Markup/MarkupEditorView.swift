//
//  MarkupEditorView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI
import UIKit

struct MarkupEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MarkupEditorViewModel

    init(screenshotId: String, baseImage: UIImage, metadataManager: MetadataManager) {
        _viewModel = State(
            initialValue: MarkupEditorViewModel(
                screenshotId: screenshotId,
                baseImage: baseImage,
                metadataManager: metadataManager
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                canvasSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                toolBar
            }
            .background(Color.black)
            .navigationTitle("Markup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Done") {
                            Task {
                                let shouldDismiss = await viewModel.save()
                                if shouldDismiss {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .alert(
                "Saved with warning",
                isPresented: Binding(
                    get: { viewModel.saveWarning != nil },
                    set: { if !$0 { viewModel.saveWarning = nil } }
                )
            ) {
                Button("OK") {
                    viewModel.saveWarning = nil
                    dismiss()
                }
            } message: {
                Text(viewModel.saveWarning ?? "")
            }
        }
    }

    private var canvasSection: some View {
        GeometryReader { geo in
            let imageSize = viewModel.baseImage.size
            let scale = Self.fitScale(imageSize: imageSize, in: geo.size)
            ZStack {
                Color.black
                ZStack {
                    Image(uiImage: viewModel.baseImage)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: imageSize.width, height: imageSize.height)

                    PencilCanvasView(
                        drawing: Binding(
                            get: { viewModel.drawing },
                            set: {
                                viewModel.drawing = $0
                                viewModel.refreshUndoState()
                            }
                        ),
                        inkColor: viewModel.inkUIColor,
                        inkWidth: viewModel.inkWidth,
                        allowsDrawing: true,
                        onUndoManagerChange: { manager in
                            viewModel.bindUndoManager(manager)
                        }
                    )
                    .frame(width: imageSize.width, height: imageSize.height)
                }
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private var toolBar: some View {
        HStack(spacing: 20) {
            Button {
                viewModel.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .semibold))
            }
            .disabled(!viewModel.canUndo || viewModel.isSaving)
            .accessibilityLabel("Undo")

            Button {
                viewModel.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 18, weight: .semibold))
            }
            .disabled(!viewModel.canRedo || viewModel.isSaving)
            .accessibilityLabel("Redo")

            Spacer()

            HStack(spacing: 8) {
                Ph.highlighter.regular
                    .color(ScreenbaseColors.ink)
                    .frame(width: 22, height: 22)
                Text("Highlighter")
                    .font(ScreenbaseFonts.display(size: 15, weight: .semibold))
                    .foregroundStyle(ScreenbaseColors.ink)
            }

            Spacer()

            ColorPicker("Color", selection: Binding(
                get: { viewModel.inkColor },
                set: { viewModel.inkColor = $0 }
            ), supportsOpacity: false)
            .labelsHidden()
            .disabled(viewModel.isSaving)
            .accessibilityLabel("Highlighter color")
        }
        .foregroundStyle(ScreenbaseColors.ink)
        .padding(.horizontal, ScreenbaseMetrics.edgePadding)
        .padding(.vertical, 14)
        .background(ScreenbaseColors.elevated)
    }

    private static func fitScale(imageSize: CGSize, in container: CGSize) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0,
              container.width > 0, container.height > 0
        else { return 1 }
        return min(container.width / imageSize.width, container.height / imageSize.height)
    }
}

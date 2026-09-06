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
                        tool: viewModel.pkTool,
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
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MarkupTool.allCases) { tool in
                        toolButton(tool)
                    }
                }
                .padding(.horizontal, ScreenbaseMetrics.edgePadding)
            }

            HStack(spacing: 16) {
                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 17, weight: .semibold))
                }
                .disabled(!viewModel.canUndo || viewModel.isSaving)
                .accessibilityLabel("Undo")

                Button {
                    viewModel.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 17, weight: .semibold))
                }
                .disabled(!viewModel.canRedo || viewModel.isSaving)
                .accessibilityLabel("Redo")

                Text(viewModel.selectedTool.title)
                    .font(ScreenbaseFonts.display(size: 15, weight: .semibold))
                    .foregroundStyle(ScreenbaseColors.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.showsColorPicker {
                    ColorPicker(
                        "Color",
                        selection: Binding(
                            get: { viewModel.inkColor },
                            set: { viewModel.inkColor = $0 }
                        ),
                        supportsOpacity: false
                    )
                    .labelsHidden()
                    .disabled(viewModel.isSaving)
                    .accessibilityLabel("Ink color")
                }
            }
            .foregroundStyle(ScreenbaseColors.ink)
            .padding(.horizontal, ScreenbaseMetrics.edgePadding)
        }
        .padding(.vertical, 12)
        .background(ScreenbaseColors.elevated)
    }

    private func toolButton(_ tool: MarkupTool) -> some View {
        let isSelected = viewModel.selectedTool == tool
        return Button {
            viewModel.selectTool(tool)
        } label: {
            tool.icon.bold
                .color(isSelected ? ScreenbaseColors.ink : ScreenbaseColors.gray)
                .frame(width: 22, height: 22)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? ScreenbaseColors.lightGray : Color.clear)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(ScreenbaseColors.ink, lineWidth: isSelected ? 1.5 : 0)
                }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .accessibilityLabel(tool.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static func fitScale(imageSize: CGSize, in container: CGSize) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0,
              container.width > 0, container.height > 0
        else { return 1 }
        return min(container.width / imageSize.width, container.height / imageSize.height)
    }
}

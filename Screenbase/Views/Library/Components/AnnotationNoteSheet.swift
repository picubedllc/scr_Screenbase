//
//  AnnotationNoteSheet.swift
//  Screenbase
//

import SwiftUI

/// Bottom sheet for adding/editing a freeform note plus optional suggested tag chips.
struct AnnotationNoteSheet: View {
    @Bindable var viewModel: AnnotationNoteSheetViewModel
    var onDismiss: () -> Void

    private let chipColumns = [
        GridItem(.adaptive(minimum: 72), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextEditor(text: $viewModel.draft)
                        .font(ScreenbaseFonts.display(size: 17, weight: .regular))
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(ScreenbaseColors.lightGray)
                        )

                    if !viewModel.suggestedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Suggested tags")
                                .font(ScreenbaseFonts.display(size: 14, weight: .semibold))
                                .foregroundStyle(ScreenbaseColors.gray)

                            LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                                ForEach(viewModel.suggestedTags) { tag in
                                    suggestedTagChip(tag)
                                }
                            }
                        }
                    }
                }
                .padding(ScreenbaseMetrics.edgePadding)
            }
            .screenbaseBackground()
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.allowsSkip ? "Skip" : "Cancel") {
                        if viewModel.allowsSkip {
                            viewModel.skip()
                        } else {
                            onDismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.save() }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func suggestedTagChip(_ tag: TagRecord) -> some View {
        let isSelected = viewModel.selectedTagIds.contains(tag.id)
        return Button {
            viewModel.toggleTag(tag.id)
        } label: {
            Text(tag.name)
                .font(ScreenbaseFonts.display(size: 13, weight: isSelected ? .bold : .semibold))
                .foregroundStyle(ScreenbaseColors.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(ScreenbaseColors.lightGray)
                )
                .overlay {
                    Capsule()
                        .strokeBorder(ScreenbaseColors.ink, lineWidth: isSelected ? 1.5 : 0)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tag.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Edit") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    AnnotationNoteSheet(
        viewModel: AnnotationNoteSheetViewModel(
            screenshotId: ScreenshotRecord.mock.id,
            metadataManager: metadata,
            initialDraft: "Login flow"
        ),
        onDismiss: {}
    )
    .task {
        try? await metadata.upsertScreenshot(.mock)
        _ = try? await metadata.createTag(name: "bug")
        _ = try? await metadata.createTag(name: "design")
    }
}

#Preview("Capture skippable") {
    let metadata = MetadataManager(local: InMemoryLocalMetadataStore(), remote: MockMetadataService())
    AnnotationNoteSheet(
        viewModel: AnnotationNoteSheetViewModel(
            screenshotId: ScreenshotRecord.mock.id,
            metadataManager: metadata,
            title: "Add a note",
            allowsSkip: true
        ),
        onDismiss: {}
    )
    .task {
        try? await metadata.upsertScreenshot(.mock)
    }
}

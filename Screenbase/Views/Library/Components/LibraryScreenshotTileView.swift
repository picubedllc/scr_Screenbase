//
//  LibraryScreenshotTileView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI
import UIKit

struct LibraryScreenshotTileView: View {
    var assetLocalIdentifier: String
    var isSelecting: Bool = false
    var isSelected: Bool = false
    var image: UIImage?
    var showsPlaceholder: Bool = false
    var isMissing: Bool = false
    var onTap: () -> Void = {}
    var onLongPress: () -> Void = {}

    var body: some View {
        tileContent
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: ScreenbaseMetrics.radiusThumbnail, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ScreenbaseMetrics.radiusThumbnail, style: .continuous)
                    .strokeBorder(ScreenbaseColors.ink, lineWidth: isSelected ? 2 : 0)
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelecting {
                    selectionBadge
                        .padding(8)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: ScreenbaseMetrics.radiusThumbnail, style: .continuous))
            .onTapGesture(perform: onTap)
            .onLongPressGesture(perform: onLongPress)
            .accessibilityLabel(isMissing ? "Missing screenshot" : "Screenshot")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityAction(named: "Select") {
                onLongPress()
            }
    }

    @ViewBuilder
    private var tileContent: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if isMissing {
            RoundedRectangle(cornerRadius: ScreenbaseMetrics.radiusThumbnail, style: .continuous)
                .fill(ScreenbaseColors.lightGray)
                .overlay {
                    Ph.imageBroken.regular
                        .color(ScreenbaseColors.gray)
                        .frame(width: 28, height: 28)
                }
        } else {
            RoundedRectangle(cornerRadius: ScreenbaseMetrics.radiusThumbnail, style: .continuous)
                .fill(ScreenbaseColors.lightGray)
                .overlay {
                    if !showsPlaceholder {
                        ProgressView()
                            .tint(ScreenbaseColors.gray)
                    }
                }
        }
    }

    private var selectionBadge: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(ScreenbaseColors.ink)
                Ph.check.bold
                    .color(ScreenbaseColors.background)
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(ScreenbaseColors.background.opacity(0.92))
                Circle()
                    .strokeBorder(ScreenbaseColors.ink, lineWidth: 1.5)
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}

#Preview("Selecting") {
    HStack(spacing: 12) {
        LibraryScreenshotTileView(
            assetLocalIdentifier: "mock",
            isSelecting: true,
            isSelected: false,
            showsPlaceholder: true
        )
        LibraryScreenshotTileView(
            assetLocalIdentifier: "mock-selected",
            isSelecting: true,
            isSelected: true,
            showsPlaceholder: true
        )
    }
    .frame(height: 120)
    .padding()
}

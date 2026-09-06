//
//  DangerTextViewModifier.swift
//  Screenbase
//

import SwiftUI

/// Applies the shared danger/destructive text color (`ScrRed`) for irreversible actions.
struct DangerTextViewModifier: ViewModifier {
    var size: CGFloat = 16
    var weight: Font.Weight = .semibold

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .foregroundStyle(ScreenbaseColors.red)
    }
}

extension View {
    /// Styles label text as a danger action using the asset catalog red.
    func screenbaseDangerText(
        size: CGFloat = 16,
        weight: Font.Weight = .semibold
    ) -> some View {
        modifier(DangerTextViewModifier(size: size, weight: weight))
    }
}

#Preview("Danger Text") {
    VStack(spacing: 16) {
        Text("Remove from Library")
            .screenbaseDangerText()
        Text("Delete")
            .screenbaseDangerText(size: 17, weight: .semibold)
        Button("Remove") {}
            .buttonStyle(.plain)
            .screenbaseDangerText()
    }
    .padding()
    .screenbaseBackground()
}

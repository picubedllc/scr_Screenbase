//
//  ActionButtonTipTileView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI

/// Settings tip tile inspired by NoTicket shortcut cards — Action Button / Back Tap suggestion.
struct ActionButtonTipTileView: View {
    var title: String
    var subtitle: String
    var systemImage: String = "button.programmable"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(ScreenbaseColors.background)
                .frame(width: 40, height: 40)
                .background(ScreenbaseColors.ink)
                .clipShape(Circle())

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ScreenbaseFonts.display(size: 17, weight: .bold))
                    .foregroundStyle(ScreenbaseColors.ink)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(ScreenbaseColors.gray)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
        .background(ScreenbaseColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    ActionButtonTipTileView(
        title: "Action Button",
        subtitle: "In Settings → Action Button, choose Shortcuts → Open Library."
    )
    .padding()
    .screenbaseBackground()
}

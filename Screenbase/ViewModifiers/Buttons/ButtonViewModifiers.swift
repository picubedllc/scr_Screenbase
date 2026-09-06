//
//  ButtonViewModifiers.swift
//  Screenbase
//

import SwiftUI

// MARK: - Primary (solid ink fill, capsule)

struct ScreenbasePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(ScreenbaseColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScreenbaseMetrics.buttonPaddingV)
            .background(ScreenbaseColors.ink)
            .clipShape(Capsule())
            .opacity(buttonOpacity(isPressed: configuration.isPressed, isEnabled: isEnabled))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary (light gray fill, ink type)

struct ScreenbaseSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(ScreenbaseColors.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScreenbaseMetrics.buttonPaddingV)
            .background(ScreenbaseColors.lightGray)
            .clipShape(Capsule())
            .opacity(buttonOpacity(isPressed: configuration.isPressed, isEnabled: isEnabled))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Tertiary (text-only ink)

struct ScreenbaseTertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(ScreenbaseColors.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .opacity(buttonOpacity(isPressed: configuration.isPressed, isEnabled: isEnabled))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Destructive (text-only red, PRD §24)

struct ScreenbaseDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .screenbaseDangerText()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .opacity(buttonOpacity(isPressed: configuration.isPressed, isEnabled: isEnabled))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private func buttonOpacity(isPressed: Bool, isEnabled: Bool) -> Double {
    if !isEnabled { return 0.4 }
    return isPressed ? 0.72 : 1
}

// MARK: - ButtonStyle sugar

extension ButtonStyle where Self == ScreenbasePrimaryButtonStyle {
    static var screenbasePrimary: ScreenbasePrimaryButtonStyle {
        ScreenbasePrimaryButtonStyle()
    }
}

extension ButtonStyle where Self == ScreenbaseSecondaryButtonStyle {
    static var screenbaseSecondary: ScreenbaseSecondaryButtonStyle {
        ScreenbaseSecondaryButtonStyle()
    }
}

extension ButtonStyle where Self == ScreenbaseTertiaryButtonStyle {
    static var screenbaseTertiary: ScreenbaseTertiaryButtonStyle {
        ScreenbaseTertiaryButtonStyle()
    }
}

extension ButtonStyle where Self == ScreenbaseDestructiveButtonStyle {
    static var screenbaseDestructive: ScreenbaseDestructiveButtonStyle {
        ScreenbaseDestructiveButtonStyle()
    }
}

// MARK: - View helpers (label styling without wrapping Button)

extension View {
    /// Applies primary button chrome to a label (prefer `.buttonStyle(.screenbasePrimary)` on `Button`).
    func primaryButtonStyle() -> some View {
        font(.system(size: 17, weight: .semibold))
            .foregroundStyle(ScreenbaseColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScreenbaseMetrics.buttonPaddingV)
            .background(ScreenbaseColors.ink)
            .clipShape(Capsule())
    }

    func secondaryButtonStyle() -> some View {
        font(.system(size: 17, weight: .semibold))
            .foregroundStyle(ScreenbaseColors.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScreenbaseMetrics.buttonPaddingV)
            .background(ScreenbaseColors.lightGray)
            .clipShape(Capsule())
    }

    func tertiaryButtonStyle() -> some View {
        font(.system(size: 16, weight: .semibold))
            .foregroundStyle(ScreenbaseColors.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }

    func destructiveButtonStyle() -> some View {
        screenbaseDangerText()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
    }
}

#Preview("Button styles") {
    VStack(spacing: 16) {
        Button("Continue") {}
            .buttonStyle(.screenbasePrimary)
        Button("Not now") {}
            .buttonStyle(.screenbaseSecondary)
        Button("Skip") {}
            .buttonStyle(.screenbaseTertiary)
        Button("Log out") {}
            .buttonStyle(.screenbaseDestructive)
    }
    .padding(ScreenbaseMetrics.edgePadding)
    .screenbaseBackground()
}

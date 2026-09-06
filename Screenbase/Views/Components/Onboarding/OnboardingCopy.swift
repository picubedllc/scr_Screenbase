//
//  OnboardingCopy.swift
//  Screenbase
//

import Foundation

enum OnboardingCopy {
    enum Welcome {
        static let title = "Welcome to Screenbase"
        static let subtitle = "Your screenshots stay on your device."
        static let steps: [(Int, String)] = [
            (1, "Screenbase finds screenshots already in Photos. Nothing is uploaded."),
            (2, "Photos remains the system of record. We store references and notes, not copies."),
            (3, "Annotate why you saved something so you can find it later.")
        ]
        static let continueCTA = "Continue"
    }

    enum PhotosPermission {
        static let title = "Allow Photos access"
        static let subtitle =
            "Screenbase needs full library access to find screenshots already on this iPhone. We never upload them."
        static let steps: [(Int, String)] = [
            (1, "We look for screenshot assets via Photos metadata — not by scanning every picture."),
            (2, "No Screenbase account is required. Analysis stays on-device."),
            (3, "You can change this later in iOS Settings.")
        ]
        static let enableCTA = "Allow Photos Access"
        static let notNowCTA = "Not now"
    }

    enum InitialScan {
        static let title = "Finding your screenshots"
        static let scanningSubtitle = "Looking through Photos for screenshots. OCR indexing comes later, on-device."
        static let completeSubtitle = "These stay in Photos. Screenbase will organize references as you go."
        static let deniedTitle = "Photos access is off"
        static let deniedSubtitle =
            "You can still use Screenbase, but your library will stay empty until Photos access is granted in Settings."
        static let limitedTitle = "Limited Photos access"
        static let limitedSubtitle =
            "Screenbase can only see screenshots you selected. Open Settings to grant full library access."
        static let continueCTA = "Get started"
        static let openSettingsCTA = "Open Settings"
    }
}

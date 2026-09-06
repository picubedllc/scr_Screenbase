//
//  SettingsCopy.swift
//  Screenbase
//

import Foundation

enum SettingsCopy {
    enum PhotosAccess {
        static let title = "Photos Access"
        static let authorized = "Full access"
        static let limited = "Limited"
        static let denied = "Off"
        static let notDetermined = "Not set"
    }

    enum ImportExisting {
        static let title = "Import Existing Screenshots"
        static let message = """
        Scan Photos for screenshots that aren’t in Screenbase yet. Originals stay in Photos unless Delete After Import is on.
        """
    }

    enum OnDeviceAnalysis {
        static let title = "On-Device Analysis"
        static let message = """
        Semantic and visual analysis runs on this device. Your screenshot library stays local and is not uploaded to Screenbase.
        """
    }

    enum AIProcessing {
        static let title = "AI Processing"
        static let message = """
        Screenbase does not send screenshots to a server or hosted model. Analysis, OCR, and tagging are designed to run on-device.
        """
    }

    enum ShareExtension {
        static let title = "Share Extension"
        static let message = """
        In Photos or any app, open the Share sheet and choose Open in Screenbase to import a screenshot.

        If you don’t see it, tap More in the Share sheet and enable Screenbase.
        """
    }

    enum ScreenbasePro {
        static let title = "Screenbase Pro"
        static let message = """
        Screenbase Pro unlocks the full library, advanced search, and stitching. Tap Screenbase Pro in Settings to subscribe or manage your plan.
        """
    }

    enum WhatsNew {
        static let title = "What’s New"
        static let message = """
        Welcome to Screenbase.

        Import screenshots from Photos, search the text and visuals on them, and keep everything organized in collections — all on-device.
        """
    }
}

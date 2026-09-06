//
//  SettingsListView.swift
//  Screenbase
//

import PhosphorSwift
import RevenueCatUI
import StoreKit
import SwiftUI
import UIKit

struct SettingsListView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(AppState.self) private var appState
    @Environment(PhotosManager.self) private var photosManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.requestReview) private var requestReview
    @State private var isRestoreAlertPresented = false
    @State private var isRestartOnboardingPresented = false
    @State private var isPaywallPresented = false
    @State private var isCustomerCenterPresented = false
    @State private var restoreAlertMessage = "No purchases to restore."

    var body: some View {
        List {
            Section("Account") {
                Button {
                    if purchaseManager.isPremiumUnlocked {
                        isCustomerCenterPresented = true
                    } else {
                        isPaywallPresented = true
                    }
                } label: {
                    SettingsRowView(
                        icon: .crown,
                        title: "Screenbase Pro",
                        value: purchaseManager.isPremiumUnlocked ? "Subscribed" : "Not subscribed"
                    )
                }

                Button {
                    Task {
                        await purchaseManager.restorePurchases()
                        restoreAlertMessage = purchaseManager.statusMessage
                            ?? "No purchases to restore."
                        isRestoreAlertPresented = true
                    }
                } label: {
                    SettingsRowView(icon: .arrowClockwise, title: "Restore Purchases")
                }
            }
            .screenbaseListRow()

            Section("Import") {
                Button {
                    SystemSettings.openAppSettings()
                } label: {
                    SettingsRowView(
                        icon: .imageSquare,
                        title: SettingsCopy.PhotosAccess.title,
                        value: photosAccessValue
                    )
                }

                Toggle(isOn: $viewModel.deleteAfterImport) {
                    SettingsRowView(icon: .trash, title: "Delete After Import")
                }

                Toggle(isOn: $viewModel.autoGroupScreenshots) {
                    SettingsRowView(icon: .stack, title: "Auto-Group Screenshots")
                }

                NavigationLink {
                    SettingsDetailView(
                        title: SettingsCopy.ImportExisting.title,
                        message: SettingsCopy.ImportExisting.message
                    )
                } label: {
                    SettingsRowView(icon: .downloadSimple, title: "Import Existing Screenshots")
                }
            }
            .screenbaseListRow()

            Section("Search") {
                Toggle(isOn: $viewModel.includeScreenshotText) {
                    SettingsRowView(icon: .textT, title: "Include Screenshot Text")
                }

                Toggle(isOn: $viewModel.includeVisualAnalysis) {
                    SettingsRowView(icon: .image, title: "Include Visual Analysis")
                }
            }
            .screenbaseListRow()

            Section("Organization") {
                Toggle(isOn: $viewModel.autoTag) {
                    SettingsRowView(icon: .tag, title: "Auto-Tag")
                }

                Toggle(isOn: $viewModel.automaticAnalysis) {
                    SettingsRowView(icon: .sparkle, title: "Automatic Analysis")
                }

                Toggle(isOn: $viewModel.showAnnotationsByDefault) {
                    SettingsRowView(icon: .eye, title: "Show Annotations by Default")
                }
            }
            .screenbaseListRow()

            Section("Appearance") {
                NavigationLink {
                    AppearanceSettingsView(appearance: $viewModel.appearance)
                } label: {
                    SettingsRowView(
                        icon: .circleHalf,
                        title: "Appearance",
                        value: viewModel.appearance.title
                    )
                }
            }
            .screenbaseListRow()

            Section("Storage") {
                SettingsRowView(icon: .hardDrives, title: "Storage Used", value: viewModel.storageUsedDisplay)
            }
            .screenbaseListRow()

            Section("Privacy") {
                NavigationLink {
                    SettingsDetailView(
                        title: SettingsCopy.OnDeviceAnalysis.title,
                        message: SettingsCopy.OnDeviceAnalysis.message
                    )
                } label: {
                    SettingsRowView(icon: .cpu, title: "On-Device Analysis")
                }

                Toggle(isOn: $viewModel.analyticsEnabled) {
                    SettingsRowView(icon: .chartBar, title: "Analytics")
                }

                NavigationLink {
                    SettingsDetailView(
                        title: SettingsCopy.AIProcessing.title,
                        message: SettingsCopy.AIProcessing.message
                    )
                } label: {
                    SettingsRowView(icon: .brain, title: "AI Processing")
                }
            }
            .screenbaseListRow()

            Section("About") {
                NavigationLink {
                    SettingsDetailView(
                        title: SettingsCopy.WhatsNew.title,
                        message: SettingsCopy.WhatsNew.message
                    )
                } label: {
                    SettingsRowView(icon: .megaphone, title: "What’s New")
                }

                if let url = URL(string: "mailto:\(Constants.feedbackEmail)") {
                    Link(destination: url) {
                        SettingsRowView(icon: .paperPlaneTilt, title: "Send Feedback")
                    }
                }

                Button {
                    requestReview()
                } label: {
                    SettingsRowView(icon: .star, title: "Rate Screenbase")
                }

                NavigationLink {
                    SettingsDetailView(
                        title: SettingsCopy.ShareExtension.title,
                        message: SettingsCopy.ShareExtension.message
                    )
                } label: {
                    SettingsRowView(icon: .export, title: "Share Extension")
                }

                NavigationLink {
                    SettingsLegalView()
                } label: {
                    SettingsRowView(icon: .fileText, title: "Privacy Policy / Terms")
                }

                SettingsRowView(icon: .info, title: "Version", value: viewModel.versionDisplay)

                Button {
                    isRestartOnboardingPresented = true
                } label: {
                    SettingsRowView(icon: .arrowCounterClockwise, title: "Restart Onboarding")
                }
            }
            .screenbaseListRow()
        }
        .screenbaseListStyle()
        .sheet(isPresented: $isPaywallPresented) {
            ScreenbasePaywallHost(isPresented: $isPaywallPresented)
        }
        .sheet(isPresented: $isCustomerCenterPresented) {
            CustomerCenterView()
        }
        .alert("Restore Purchases", isPresented: $isRestoreAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreAlertMessage)
        }
        .alert("Restart onboarding?", isPresented: $isRestartOnboardingPresented) {
            Button("Restart", role: .destructive) {
                appState.updateViewState(showMainApp: false)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll go through the intro again.")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            photosManager.refreshAuthorizationStatus()
        }
    }

    private var photosAccessValue: String {
        switch photosManager.authorizationStatus {
        case .authorized:
            SettingsCopy.PhotosAccess.authorized
        case .limited:
            SettingsCopy.PhotosAccess.limited
        case .denied:
            SettingsCopy.PhotosAccess.denied
        case .notDetermined:
            SettingsCopy.PhotosAccess.notDetermined
        }
    }
}

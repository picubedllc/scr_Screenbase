//
//  ScreenbaseOnboardingView.swift
//  Screenbase
//

import PhosphorSwift
import SwiftUI
import UIKit

struct ScreenbaseOnboardingView: View {
    @Bindable var appState: AppState
    @Environment(UserManager.self) private var userManager
    @State private var viewModel: OnboardingViewModel

    init(
        appState: AppState,
        photosManager: PhotosManager,
        screenshotManager: ScreenshotManager? = nil,
        startStep: OnboardingViewModel.Step = .welcome
    ) {
        self.appState = appState
        _viewModel = State(
            initialValue: OnboardingViewModel(
                photosManager: photosManager,
                screenshotManager: screenshotManager,
                step: startStep
            )
        )
    }

    var body: some View {
        ZStack {
            ScreenbaseColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch viewModel.step {
                    case .welcome:
                        ScrollView(showsIndicators: false) {
                            welcomeContent
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    case .photosPermission:
                        ScrollView(showsIndicators: false) {
                            photosPermissionContent
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    case .initialScan:
                        scanContent
                            .padding(.horizontal, ScreenbaseMetrics.edgePadding)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                VStack(spacing: 12) {
                    Button(viewModel.primaryButtonTitle) {
                        HapticsManager.instance.mediumImpact()
                        handlePrimaryAction()
                    }
                    .buttonStyle(.screenbasePrimary)
                    .disabled(viewModel.step == .initialScan && !viewModel.canContinueFromScan)

                    if viewModel.step == .photosPermission {
                        Button(OnboardingCopy.PhotosPermission.notNowCTA) {
                            viewModel.skipPhotosPermission()
                        }
                        .buttonStyle(.screenbaseTertiary)
                    }

                    if viewModel.showsOpenSettings {
                        Button(OnboardingCopy.InitialScan.openSettingsCTA) {
                            viewModel.openSystemSettings()
                        }
                        .buttonStyle(.screenbaseTertiary)
                    }
                }
                .padding(.horizontal, ScreenbaseMetrics.edgePadding)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .task(id: viewModel.step) {
            await viewModel.startInitialScanIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleReturnFromSettings()
        }
    }

    private func handleReturnFromSettings() {
        guard viewModel.step == .initialScan else { return }
        let previous = viewModel.photosStatus
        viewModel.refreshPhotosStatus()
        if previous != viewModel.photosStatus {
            Task {
                await viewModel.startInitialScanIfNeeded()
            }
        }
    }

    private func handlePrimaryAction() {
        switch viewModel.step {
        case .welcome:
            viewModel.continueFromWelcome()
        case .photosPermission:
            Task {
                await viewModel.requestPhotosAccess()
            }
        case .initialScan:
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        Task {
            try? await userManager.markOnboardingCompleteForCurrentUser()
            appState.updateViewState(showMainApp: true)
        }
    }

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Ph.images.bold
                    .color(ScreenbaseColors.ink)
                    .frame(width: 40, height: 40)

                Text(OnboardingCopy.Welcome.title)
                    .displayFont(size: 32)
                    .foregroundStyle(ScreenbaseColors.ink)

                Text(OnboardingCopy.Welcome.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(ScreenbaseColors.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(OnboardingCopy.Welcome.steps, id: \.0) { number, text in
                    NumberedStepCardView(number: number, text: text)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var photosPermissionContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Ph.imageSquare.bold
                    .color(ScreenbaseColors.ink)
                    .frame(width: 40, height: 40)

                Text(OnboardingCopy.PhotosPermission.title)
                    .displayFont(size: 32)
                    .foregroundStyle(ScreenbaseColors.ink)

                Text(OnboardingCopy.PhotosPermission.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(ScreenbaseColors.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(OnboardingCopy.PhotosPermission.steps, id: \.0) { number, text in
                    NumberedStepCardView(number: number, text: text)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var scanContent: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            VStack(spacing: 16) {
                scanIcon
                    .frame(width: 40, height: 40)

                Text(scanTitle)
                    .displayFont(size: 28)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ScreenbaseColors.ink)

                Text(scanSubtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(ScreenbaseColors.gray)
                    .multilineTextAlignment(.center)

                if viewModel.isScanning {
                    ProgressView()
                        .tint(ScreenbaseColors.ink)
                        .padding(.top, 8)
                } else if let count = viewModel.screenshotCount {
                    Text(scanCountLabel(count))
                        .displayFont(size: 32)
                        .foregroundStyle(ScreenbaseColors.ink)
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var scanIcon: some View {
        if viewModel.photosStatus == .denied {
            Ph.warningCircle.bold
                .color(ScreenbaseColors.ink)
        } else if viewModel.photosStatus == .limited {
            Ph.warningCircle.bold
                .color(ScreenbaseColors.ink)
        } else if viewModel.isScanning {
            Ph.magnifyingGlass.bold
                .color(ScreenbaseColors.ink)
        } else {
            Ph.checkCircle.bold
                .color(ScreenbaseColors.ink)
        }
    }

    private var scanTitle: String {
        switch viewModel.photosStatus {
        case .denied:
            OnboardingCopy.InitialScan.deniedTitle
        case .limited:
            OnboardingCopy.InitialScan.limitedTitle
        case .authorized, .notDetermined:
            OnboardingCopy.InitialScan.title
        }
    }

    private var scanSubtitle: String {
        switch viewModel.photosStatus {
        case .denied:
            OnboardingCopy.InitialScan.deniedSubtitle
        case .limited:
            OnboardingCopy.InitialScan.limitedSubtitle
        case .authorized, .notDetermined:
            if viewModel.isScanning {
                OnboardingCopy.InitialScan.scanningSubtitle
            } else {
                OnboardingCopy.InitialScan.completeSubtitle
            }
        }
    }

    private func scanCountLabel(_ count: Int) -> String {
        let noun = count == 1 ? "screenshot" : "screenshots"
        return "\(count) \(noun) found"
    }
}

#Preview("Welcome") {
    let photos = PhotosManager(service: MockPhotosService())
    return ScreenbaseOnboardingView(appState: AppState(showMainApp: false), photosManager: photos)
        .environment(UserManager(services: MockUserServices()))
}

#Preview("Photos") {
    let photos = PhotosManager(service: MockPhotosService())
    return ScreenbaseOnboardingView(
        appState: AppState(showMainApp: false),
        photosManager: photos,
        startStep: .photosPermission
    )
    .environment(UserManager(services: MockUserServices()))
}

#Preview("Scan") {
    let photos = PhotosManager(service: MockPhotosService(status: .authorized, screenshotCount: 48))
    return ScreenbaseOnboardingView(
        appState: AppState(showMainApp: false),
        photosManager: photos,
        startStep: .initialScan
    )
    .environment(UserManager(services: MockUserServices()))
}

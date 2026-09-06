//
//  OnboardingViewModel.swift
//  Screenbase
//

import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable, Equatable {
        case welcome
        case photosPermission
        case initialScan
    }

    private(set) var step: Step
    private(set) var photosStatus: PhotosAuthorizationStatus
    private(set) var isRequestingPhotos = false
    private(set) var isScanning = false
    private(set) var screenshotCount: Int?
    private(set) var scanFailed = false

    private let photosManager: PhotosManager
    private let screenshotManager: ScreenshotManager?

    init(
        photosManager: PhotosManager,
        screenshotManager: ScreenshotManager? = nil,
        step: Step = .welcome
    ) {
        self.photosManager = photosManager
        self.screenshotManager = screenshotManager
        self.step = step
        photosStatus = photosManager.authorizationStatus
    }

    var primaryButtonTitle: String {
        switch step {
        case .welcome:
            OnboardingCopy.Welcome.continueCTA
        case .photosPermission:
            OnboardingCopy.PhotosPermission.enableCTA
        case .initialScan:
            OnboardingCopy.InitialScan.continueCTA
        }
    }

    var canContinueFromScan: Bool {
        !isScanning
    }

    /// Denied or limited — user can open Settings to grant full access.
    var showsOpenSettings: Bool {
        step == .initialScan && (photosStatus == .denied || photosStatus == .limited)
    }

    func continueFromWelcome() {
        step = .photosPermission
        photosStatus = photosManager.authorizationStatus
    }

    func requestPhotosAccess() async {
        isRequestingPhotos = true
        photosStatus = await photosManager.requestAuthorization()
        isRequestingPhotos = false
        step = .initialScan
    }

    func skipPhotosPermission() {
        photosStatus = photosManager.authorizationStatus
        step = .initialScan
    }

    func openSystemSettings() {
        SystemSettings.openAppSettings()
    }

    func refreshPhotosStatus() {
        photosManager.refreshAuthorizationStatus()
        photosStatus = photosManager.authorizationStatus
    }

    func startInitialScanIfNeeded() async {
        guard step == .initialScan, screenshotCount == nil, !isScanning else { return }
        photosStatus = photosManager.authorizationStatus
        guard photosStatus == .authorized || photosStatus == .limited else { return }

        isScanning = true
        scanFailed = false
        do {
            async let count = photosManager.screenshotCount()
            async let discovery: Void = startScreenshotDiscoveryIfAuthorized()
            screenshotCount = try await count
            await discovery
        } catch {
            scanFailed = true
        }
        isScanning = false
    }

    private func startScreenshotDiscoveryIfAuthorized() async {
        guard photosStatus == .authorized || photosStatus == .limited else { return }
        await screenshotManager?.startDiscovery()
    }
}

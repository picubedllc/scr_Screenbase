import Foundation
@testable import Screenbase
import Testing

@Suite("OnboardingViewModel Tests")
struct OnboardingViewModel_Tests {
    @Test("Welcome continue advances to photos permission")
    @MainActor
    func continueFromWelcomeAdvancesToPhotos() {
        let photos = PhotosManager(service: MockPhotosService())
        let sut = OnboardingViewModel(photosManager: photos)

        sut.continueFromWelcome()

        #expect(sut.step == .photosPermission)
    }

    @Test("Photos request authorizes and advances to scan")
    @MainActor
    func requestPhotosAccessAdvancesToScan() async {
        let photos = PhotosManager(service: MockPhotosService(status: .notDetermined, screenshotCount: 7))
        let sut = OnboardingViewModel(photosManager: photos)

        await sut.requestPhotosAccess()

        #expect(sut.photosStatus == .authorized)
        #expect(sut.step == .initialScan)
    }

    @Test("Skip photos still advances to scan")
    @MainActor
    func skipPhotosPermissionAdvancesToScan() {
        let photos = PhotosManager(service: MockPhotosService(status: .notDetermined))
        let sut = OnboardingViewModel(photosManager: photos)

        sut.skipPhotosPermission()

        #expect(sut.step == .initialScan)
        #expect(sut.photosStatus == .notDetermined)
    }

    @Test("Authorized scan records screenshot count")
    @MainActor
    func startInitialScanRecordsCount() async {
        let photos = PhotosManager(service: MockPhotosService(status: .authorized, screenshotCount: 21))
        let sut = OnboardingViewModel(photosManager: photos, step: .initialScan)

        await sut.startInitialScanIfNeeded()

        #expect(sut.screenshotCount == 21)
        #expect(sut.isScanning == false)
        #expect(sut.canContinueFromScan)
    }

    @Test("Authorized scan starts screenshot discovery")
    @MainActor
    func startInitialScanStartsDiscovery() async {
        let photos = PhotosManager(service: MockPhotosService(status: .authorized, screenshotCount: 3))
        let screenshotService = MockScreenshotService(
            screenshots: [
                DiscoveredScreenshot(assetLocalIdentifier: "a", creationDate: Date())
            ]
        )
        let screenshots = ScreenshotManager(
            service: screenshotService,
            index: InMemoryScreenshotIndex()
        )
        let sut = OnboardingViewModel(
            photosManager: photos,
            screenshotManager: screenshots,
            step: .initialScan
        )

        await sut.startInitialScanIfNeeded()

        #expect(sut.screenshotCount == 3)
        #expect(!screenshots.discoveredScreenshots.isEmpty)
    }

    @Test("Photos request alone does not start discovery")
    @MainActor
    func requestPhotosAccessDoesNotStartDiscovery() async {
        let photos = PhotosManager(service: MockPhotosService(status: .notDetermined, screenshotCount: 3))
        let screenshots = ScreenshotManager(
            service: MockScreenshotService(),
            index: InMemoryScreenshotIndex()
        )
        let sut = OnboardingViewModel(photosManager: photos, screenshotManager: screenshots)

        await sut.requestPhotosAccess()

        #expect(sut.step == .initialScan)
        #expect(screenshots.discoveredScreenshots.isEmpty)
        #expect(screenshots.isObserving == false)
    }

    @Test("Denied photos skips scan")
    @MainActor
    func deniedPhotosSkipsScan() async {
        let photos = PhotosManager(service: MockPhotosService(status: .denied, screenshotCount: 21))
        let sut = OnboardingViewModel(photosManager: photos, step: .initialScan)

        await sut.startInitialScanIfNeeded()

        #expect(sut.screenshotCount == nil)
        #expect(sut.isScanning == false)
        #expect(sut.canContinueFromScan)
        #expect(sut.showsOpenSettings)
    }

    @Test("Limited photos shows open settings and still scans")
    @MainActor
    func limitedPhotosShowsOpenSettingsAndScans() async {
        let photos = PhotosManager(service: MockPhotosService(status: .limited, screenshotCount: 4))
        let sut = OnboardingViewModel(photosManager: photos, step: .initialScan)

        await sut.startInitialScanIfNeeded()

        #expect(sut.screenshotCount == 4)
        #expect(sut.showsOpenSettings)
    }

    @Test("Authorized scan hides open settings")
    @MainActor
    func authorizedScanHidesOpenSettings() async {
        let photos = PhotosManager(service: MockPhotosService(status: .authorized, screenshotCount: 2))
        let sut = OnboardingViewModel(photosManager: photos, step: .initialScan)

        await sut.startInitialScanIfNeeded()

        #expect(sut.showsOpenSettings == false)
    }

    @Test("Refresh photos status picks up service changes")
    @MainActor
    func refreshPhotosStatusUpdatesFromService() {
        let service = MockPhotosService(status: .denied)
        let photos = PhotosManager(service: service)
        let sut = OnboardingViewModel(photosManager: photos, step: .initialScan)

        #expect(sut.photosStatus == .denied)
        #expect(sut.showsOpenSettings)

        service.authorizationStatus = .authorized
        sut.refreshPhotosStatus()

        #expect(sut.photosStatus == .authorized)
        #expect(sut.showsOpenSettings == false)
    }
}

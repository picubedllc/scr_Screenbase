//
//  AppDelegate.swift
//  Screenbase
//

import FirebaseCore
import Foundation
import UIKit

enum BuildConfiguration {
    case dev
    case prod

    func configureFirebase() {
        switch self {
        case .dev:
            let plist = Self.googleServicePlistPath(resourceName: "GoogleService-Info-Dev")
            guard let options = FirebaseOptions(contentsOfFile: plist) else {
                fatalError("Invalid Firebase plist at \(plist).")
            }
            FirebaseApp.configure(options: options)
        case .prod:
            let plist = Self.googleServicePlistPath(resourceName: "GoogleService-Info-Prod")
            guard let options = FirebaseOptions(contentsOfFile: plist) else {
                fatalError("Invalid Firebase plist at \(plist).")
            }
            FirebaseApp.configure(options: options)
        }
    }

    /// Resolves `GoogleServicePLists/<name>.plist` when present in the bundle, otherwise the bundle root.
    private static func googleServicePlistPath(resourceName: String) -> String {
        if let path = Bundle.main.path(forResource: resourceName, ofType: "plist", inDirectory: "GoogleServicePLists") {
            return path
        }
        guard let path = Bundle.main.path(forResource: resourceName, ofType: "plist") else {
            fatalError(
                "Missing \(resourceName).plist for Firebase. Add it under Screenbase/GoogleServicePLists/."
            )
        }
        return path
    }
}

struct AppDependencies {
    let authManager: AuthManager
    let userManager: UserManager
    let photosManager: PhotosManager
    let purchaseManager: PurchaseManager
    let metadataManager: MetadataManager
    let screenshotManager: ScreenshotManager
    let ocrManager: OCRManager

    init(
        authManager: AuthManager,
        userManager: UserManager,
        photosManager: PhotosManager,
        purchaseManager: PurchaseManager,
        metadataManager: MetadataManager,
        screenshotManager: ScreenshotManager,
        ocrManager: OCRManager
    ) {
        self.authManager = authManager
        self.userManager = userManager
        self.photosManager = photosManager
        self.purchaseManager = purchaseManager
        self.metadataManager = metadataManager
        self.screenshotManager = screenshotManager
        self.ocrManager = ocrManager
    }

    init(configuration: BuildConfiguration) {
        switch configuration {
        case .dev, .prod:
            let metadataManager = MetadataManager(
                local: FileLocalMetadataStore(),
                remote: FirestoreMetadataService(),
                drawingStore: FileAnnotationDrawingStore(),
                imageUpload: FirebaseImageUploadService()
            )
            let photosManager = PhotosManager(service: PhotosServiceLive())
            self.init(
                authManager: AuthManager(service: FirebaseAuthServiceLive()),
                userManager: UserManager(services: ProductionUserServices()),
                photosManager: photosManager,
                purchaseManager: PurchaseManager(service: RevenueCatPurchaseService()),
                metadataManager: metadataManager,
                screenshotManager: ScreenshotManager(
                    service: PhotosScreenshotService(),
                    index: metadataManager
                ),
                ocrManager: OCRManager(
                    service: VisionScreenshotOCRService(),
                    metadataManager: metadataManager,
                    photosManager: photosManager
                )
            )
        }
    }

    static var mock: AppDependencies {
        let metadataManager = MetadataManager(
            local: InMemoryLocalMetadataStore(),
            remote: MockMetadataService(),
            drawingStore: InMemoryAnnotationDrawingStore(),
            imageUpload: MockImageUploadService()
        )
        let photosManager = PhotosManager(service: MockPhotosService())
        return AppDependencies(
            authManager: AuthManager(service: AuthServiceMock()),
            userManager: UserManager(services: MockUserServices()),
            photosManager: photosManager,
            purchaseManager: PurchaseManager(service: MockPurchaseService()),
            metadataManager: metadataManager,
            screenshotManager: ScreenshotManager(
                service: MockScreenshotService(),
                index: metadataManager
            ),
            ocrManager: OCRManager(
                service: MockScreenshotOCRService(),
                metadataManager: metadataManager,
                photosManager: photosManager
            )
        )
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    var dependencies: AppDependencies!

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if Self.shouldUseMockDependencies {
            dependencies = .mock
            return true
        }

        let configuration: BuildConfiguration
        #if DEV
        configuration = .dev
        #else
        configuration = .prod
        #endif

        configuration.configureFirebase()
        dependencies = AppDependencies(configuration: configuration)
        dependencies.purchaseManager.configureIfNeeded()
        return true
    }

    /// Unit tests and SwiftUI previews skip Firebase so they can launch with mock managers.
    static var shouldUseMockDependencies: Bool {
        let environment = ProcessInfo.processInfo.environment
        if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return true }
        if environment["XCTestConfigurationFilePath"] != nil { return true }
        if environment["XCTestBundlePath"] != nil { return true }
        // Test host injects XCTest even when Swift Testing is the runner.
        return NSClassFromString("XCTestCase") != nil
    }
}

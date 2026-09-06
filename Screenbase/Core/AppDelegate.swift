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
    let shareImportManager: ShareImportManager

    init(
        authManager: AuthManager,
        userManager: UserManager,
        photosManager: PhotosManager,
        purchaseManager: PurchaseManager,
        metadataManager: MetadataManager,
        screenshotManager: ScreenshotManager,
        shareImportManager: ShareImportManager
    ) {
        self.authManager = authManager
        self.userManager = userManager
        self.photosManager = photosManager
        self.purchaseManager = purchaseManager
        self.metadataManager = metadataManager
        self.screenshotManager = screenshotManager
        self.shareImportManager = shareImportManager
    }

    init(configuration: BuildConfiguration) {
        switch configuration {
        case .dev, .prod:
            let sharedImages: any SharedImageStore
            if let fileStore = try? FileSharedImageStore() {
                sharedImages = fileStore
            } else {
                sharedImages = InMemorySharedImageStore()
            }
            let metadataManager = MetadataManager(
                local: FileLocalMetadataStore(),
                remote: FirestoreMetadataService(),
                drawingStore: FileAnnotationDrawingStore(),
                imageUpload: FirebaseImageUploadService(),
                sharedImageStore: sharedImages
            )
            self.init(
                authManager: AuthManager(service: FirebaseAuthServiceLive()),
                userManager: UserManager(services: ProductionUserServices()),
                photosManager: PhotosManager(
                    service: PhotosServiceLive(),
                    sharedImageStore: sharedImages
                ),
                purchaseManager: PurchaseManager(service: RevenueCatPurchaseService()),
                metadataManager: metadataManager,
                screenshotManager: ScreenshotManager(
                    service: PhotosScreenshotService(),
                    index: metadataManager
                ),
                shareImportManager: ShareImportManager(
                    sharedImageStore: sharedImages,
                    metadataManager: metadataManager
                )
            )
        }
    }

    static var mock: AppDependencies {
        let sharedImages = InMemorySharedImageStore()
        let metadataManager = MetadataManager(
            local: InMemoryLocalMetadataStore(),
            remote: MockMetadataService(),
            drawingStore: InMemoryAnnotationDrawingStore(),
            imageUpload: MockImageUploadService(),
            sharedImageStore: sharedImages
        )
        return AppDependencies(
            authManager: AuthManager(service: AuthServiceMock()),
            userManager: UserManager(services: MockUserServices()),
            photosManager: PhotosManager(
                service: MockPhotosService(),
                sharedImageStore: sharedImages
            ),
            purchaseManager: PurchaseManager(service: MockPurchaseService()),
            metadataManager: metadataManager,
            screenshotManager: ScreenshotManager(
                service: MockScreenshotService(),
                index: metadataManager
            ),
            shareImportManager: ShareImportManager(
                sharedImageStore: sharedImages,
                metadataManager: metadataManager
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

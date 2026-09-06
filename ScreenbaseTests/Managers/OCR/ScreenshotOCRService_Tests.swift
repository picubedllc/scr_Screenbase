//
//  ScreenshotOCRService_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing
import UIKit

@Suite("ScreenshotOCRService Tests")
struct ScreenshotOCRService_Tests {
    @Test("Mock OCR returns configured text")
    @MainActor
    func mockOCRReturnsConfiguredText() async throws {
        let sut = MockScreenshotOCRService(text: "hello\nworld")
        let image = try #require(UIImage(systemName: "photo"))
        let text = try await sut.recognizeText(in: image)
        #expect(text == "hello\nworld")
    }
}

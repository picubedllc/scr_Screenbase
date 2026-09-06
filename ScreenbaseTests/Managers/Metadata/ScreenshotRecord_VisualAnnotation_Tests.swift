//
//  ScreenshotRecord_VisualAnnotation_Tests.swift
//  ScreenbaseTests
//

import Foundation
@testable import Screenbase
import Testing

@Suite("ScreenshotRecord Visual Annotation Codable")
struct ScreenshotRecord_VisualAnnotation_Tests {
    @Test("Legacy payloads default hasVisualAnnotation to false")
    func legacyPayloadDefaultsVisualAnnotationFields() throws {
        let json = """
        {
          "id": "abc",
          "asset_local_identifier": "ASSET/1",
          "collection_ids": [],
          "tag_ids": [],
          "created_at": 1700000000,
          "updated_at": 1700000000
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let record = try decoder.decode(ScreenshotRecord.self, from: json)

        #expect(record.hasVisualAnnotation == false)
        #expect(record.visualAnnotationURL == nil)
    }

    @Test("Visual annotation fields encode and decode")
    func visualAnnotationFieldsRoundTrip() throws {
        let record = ScreenshotRecord(
            id: "abc",
            assetLocalIdentifier: "ASSET/1",
            hasVisualAnnotation: true,
            visualAnnotationURL: "https://example.com/a.png"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(record)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(ScreenshotRecord.self, from: data)

        #expect(decoded.hasVisualAnnotation == true)
        #expect(decoded.visualAnnotationURL == "https://example.com/a.png")
    }
}

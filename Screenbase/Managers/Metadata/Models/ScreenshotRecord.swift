//
//  ScreenshotRecord.swift
//  Screenbase
//

import Foundation

/// Local + Firestore metadata for a discovered screenshot asset.
struct ScreenshotRecord: Codable, Equatable, Identifiable, Sendable, Hashable {
    var id: String
    var assetLocalIdentifier: String
    var captureDate: Date?
    var annotationText: String?
    var hasVisualAnnotation: Bool
    var visualAnnotationURL: String?
    var collectionIds: [String]
    var tagIds: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        assetLocalIdentifier: String,
        captureDate: Date? = nil,
        annotationText: String? = nil,
        hasVisualAnnotation: Bool = false,
        visualAnnotationURL: String? = nil,
        collectionIds: [String] = [],
        tagIds: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.assetLocalIdentifier = assetLocalIdentifier
        self.captureDate = captureDate
        self.annotationText = annotationText
        self.hasVisualAnnotation = hasVisualAnnotation
        self.visualAnnotationURL = visualAnnotationURL
        self.collectionIds = collectionIds
        self.tagIds = tagIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(discovered: DiscoveredScreenshot, now: Date = Date()) {
        self.init(
            id: FirestoreDocumentID.fromAssetLocalIdentifier(discovered.assetLocalIdentifier),
            assetLocalIdentifier: discovered.assetLocalIdentifier,
            captureDate: discovered.creationDate,
            createdAt: now,
            updatedAt: now
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case assetLocalIdentifier = "asset_local_identifier"
        case captureDate = "capture_date"
        case annotationText = "annotation_text"
        case hasVisualAnnotation = "has_visual_annotation"
        case visualAnnotationURL = "visual_annotation_url"
        case collectionIds = "collection_ids"
        case tagIds = "tag_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        assetLocalIdentifier = try container.decode(String.self, forKey: .assetLocalIdentifier)
        captureDate = try container.decodeIfPresent(Date.self, forKey: .captureDate)
        annotationText = try container.decodeIfPresent(String.self, forKey: .annotationText)
        hasVisualAnnotation = try container.decodeIfPresent(Bool.self, forKey: .hasVisualAnnotation) ?? false
        visualAnnotationURL = try container.decodeIfPresent(String.self, forKey: .visualAnnotationURL)
        collectionIds = try container.decodeIfPresent([String].self, forKey: .collectionIds) ?? []
        tagIds = try container.decodeIfPresent([String].self, forKey: .tagIds) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    static let mock = ScreenshotRecord(
        id: FirestoreDocumentID.fromAssetLocalIdentifier("MOCK/ASSET-1"),
        assetLocalIdentifier: "MOCK/ASSET-1",
        captureDate: Date(timeIntervalSince1970: 1_700_000_000),
        annotationText: "Login flow",
        collectionIds: ["col_1"],
        tagIds: ["tag_1"],
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}

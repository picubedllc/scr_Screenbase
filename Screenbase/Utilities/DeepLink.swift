//
//  DeepLink.swift
//  Screenbase
//

import Foundation

enum DeepLink: Equatable {
    case library
    case search
    case annotateLatest
    case importShared

    static let scheme = "screenbase"

    var absoluteString: String {
        switch self {
        case .library: "\(Self.scheme)://library"
        case .search: "\(Self.scheme)://search"
        case .annotateLatest: "\(Self.scheme)://annotate-latest"
        case .importShared: "\(Self.scheme)://import-shared"
        }
    }

    var url: URL? {
        URL(string: absoluteString)
    }

    static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        switch url.host?.lowercased() {
        case "library": return .library
        case "search": return .search
        case "annotate-latest": return .annotateLatest
        case "import-shared": return .importShared
        default: return nil
        }
    }
}

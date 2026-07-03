import Foundation

enum ImportSource: String, Codable, CaseIterable {
    case pdf
    case image
    case text

    var displayName: String {
        switch self {
        case .pdf:
            "PDF"
        case .image:
            "Image"
        case .text:
            "Text"
        }
    }
}

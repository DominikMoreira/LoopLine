import Foundation

enum ImportSource: String, Codable, CaseIterable {
    case pdf
    case image
    case text

    var displayName: LocalizedStringResource {
        switch self {
        case .pdf:
            "PDF"
        case .image:
            "Image"
        case .text:
            "Pasted Text"
        }
    }
}

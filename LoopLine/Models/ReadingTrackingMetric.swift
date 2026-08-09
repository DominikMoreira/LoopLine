import Foundation

enum ReadingTrackingMetric: String, CaseIterable, Identifiable {
    case row
    case stitches
    case repeatCount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .row:
            "Row"
        case .stitches:
            "Stitches"
        case .repeatCount:
            "Repeat"
        }
    }
}

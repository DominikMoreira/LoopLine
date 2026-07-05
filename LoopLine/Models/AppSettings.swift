import Foundation
import SwiftData

@Model
final class AppSettings {
    var largeControls: Bool
    var guideOpacity: Double

    init(
        largeControls: Bool = true,
        guideOpacity: Double = 0.35
    ) {
        self.largeControls = largeControls
        self.guideOpacity = guideOpacity
    }
}

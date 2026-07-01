import Foundation
import SwiftData

@Model
final class AppSettings {
    var readingDarkMode: Bool
    var largeControls: Bool
    var guideOpacity: Double

    init(
        readingDarkMode: Bool = false,
        largeControls: Bool = true,
        guideOpacity: Double = 0.35
    ) {
        self.readingDarkMode = readingDarkMode
        self.largeControls = largeControls
        self.guideOpacity = guideOpacity
    }
}

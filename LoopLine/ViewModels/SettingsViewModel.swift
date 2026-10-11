import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class SettingsViewModel {
    func ensureSettings(_ settings: [AppSettings], in modelContext: ModelContext) {
        guard settings.isEmpty else { return }
        modelContext.insert(AppSettings())
        save(modelContext)
    }

    func saveSettings(in modelContext: ModelContext) {
        save(modelContext)
    }

    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case let (version?, build?) where !version.isEmpty && !build.isEmpty:
            return "\(version) (\(build))"
        case let (version?, _) where !version.isEmpty:
            return version
        default:
            return "Unknown"
        }
    }

    var feedbackMailBody: String {
        String(
            localized: "Feedback email body \(appVersion) \(UIDevice.current.systemVersion) \(UIDevice.current.model)",
            comment: "Prefilled feedback email body. The first placeholder is the app version and build, the second is the iOS version, and the third is the device model."
        )
    }

    private func save(_ modelContext: ModelContext) {
        try? modelContext.save()
    }
}

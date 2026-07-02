import SwiftData
import SwiftUI

@main
struct LoopLineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Project.self,
            ProjectNote.self,
            AppSettings.self
        ])
    }
}

import SwiftData
import SwiftUI

@main
struct LoopLineApp: App {
    private let modelContainer = LoopLineModelContainer.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

private enum LoopLineModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([
            Project.self,
            ProjectNote.self,
            AppSettings.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    private static var isUITesting: Bool {
        CommandLine.arguments.contains("-uiTesting")
    }
}

import SwiftData

enum PreviewModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([
            Project.self,
            ProjectNote.self,
            AppSettings.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }
}

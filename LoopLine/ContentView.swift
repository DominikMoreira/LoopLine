import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    var body: some View {
        TabView {
            ProjectListView()
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear(perform: ensureDefaultSettings)
    }

    private func ensureDefaultSettings() {
        guard settings.isEmpty else { return }
        modelContext.insert(AppSettings())
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewModelContainer.make())
}

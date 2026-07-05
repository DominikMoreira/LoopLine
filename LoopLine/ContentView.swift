import SwiftData
import SwiftUI

struct ContentView: View {
    @Query private var settings: [AppSettings]

    private var preferredColorScheme: ColorScheme? {
        settings.first?.readingDarkMode == true ? .dark : nil
    }

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
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewModelContainer.make())
}

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        ProjectListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewModelContainer.make())
}

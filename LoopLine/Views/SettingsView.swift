import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    var body: some View {
        NavigationStack {
            Group {
                if let appSettings = settings.first {
                    SettingsForm(settings: appSettings)
                } else {
                    ProgressView()
                        .onAppear(perform: ensureSettings)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func ensureSettings() {
        guard settings.isEmpty else { return }
        modelContext.insert(AppSettings())
        try? modelContext.save()
    }
}

private struct SettingsForm: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Reading Mode") {
                Toggle("Large Controls", isOn: $settings.largeControls)
                    .onChange(of: settings.largeControls) { _, _ in saveSettings() }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Guide Opacity")
                        Spacer()
                        Text(settings.guideOpacity, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $settings.guideOpacity, in: 0.2...1.0) { isEditing in
                        if !isEditing {
                            saveSettings()
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("About") {
                LabeledContent("App", value: "LoopLine")
                LabeledContent("Version", value: appVersion)
            }
        }
    }

    private var appVersion: String {
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

    private func saveSettings() {
        try? modelContext.save()
    }
}

#Preview {
    let container = PreviewModelContainer.make()
    container.mainContext.insert(AppSettings())

    return SettingsView()
        .modelContainer(container)
}

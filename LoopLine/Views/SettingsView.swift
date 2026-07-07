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
            .navigationBarTitleDisplayMode(.large)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {
                readingModeSection
                aboutSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }

    private var readingModeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            LoopLineSectionHeader(title: "Reading Mode")

            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Large controls",
                    subtitle: "Bigger row counter buttons",
                    isOn: $settings.largeControls
                )
                .onChange(of: settings.largeControls) { _, _ in saveSettings() }

                Divider()
                    .padding(.leading, 16)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Guide opacity")
                                .font(.headline)
                            Text("Customize row highlight visibility")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(settings.guideOpacity, format: .percent.precision(.fractionLength(0)))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $settings.guideOpacity, in: 0.2...1.0) { isEditing in
                        if !isEditing {
                            saveSettings()
                        }
                    }
                    .tint(.primary)

                    HStack {
                        Text("Low")
                        Spacer()
                        Text("High")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            LoopLineSectionHeader(title: "About")

            VStack(alignment: .leading, spacing: 6) {
                Text("LoopLine")
                    .font(.headline)
                Text("Version \(appVersion) - MVP Release")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
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

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
        .padding(16)
    }
}

#Preview {
    let container = PreviewModelContainer.make()
    container.mainContext.insert(AppSettings())

    return SettingsView()
        .modelContainer(container)
}

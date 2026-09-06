import Observation
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let appSettings = settings.first {
                    SettingsForm(settings: appSettings, viewModel: viewModel)
                } else {
                    ProgressView()
                        .onAppear {
                            viewModel.ensureSettings(settings, in: modelContext)
                        }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(LoopLineTheme.appBackground.ignoresSafeArea())
        }
    }
}

private struct SettingsForm: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings
    let viewModel: SettingsViewModel

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
        .background(LoopLineTheme.appBackground.ignoresSafeArea())
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
                .onChange(of: settings.largeControls) { _, _ in
                    viewModel.saveSettings(in: modelContext)
                }

                Divider()
                    .padding(.leading, 16)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Guide opacity")
                                .font(.headline)
                            Text("Customize row highlight visibility")
                                .font(.caption)
                                .foregroundStyle(LoopLineTheme.secondaryText)
                        }

                        Spacer()

                        Text(settings.guideOpacity, format: .percent.precision(.fractionLength(0)))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(LoopLineTheme.secondaryText)
                    }

                    Slider(value: $settings.guideOpacity, in: 0.2...1.0) { isEditing in
                        if !isEditing {
                            viewModel.saveSettings(in: modelContext)
                        }
                    }
                    .tint(LoopLineTheme.primaryActionBackground)

                    HStack {
                        Text("Low")
                        Spacer()
                        Text("High")
                    }
                    .font(.caption)
                    .foregroundStyle(LoopLineTheme.secondaryText)
                }
                .padding(16)
            }
            .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous)
                    .stroke(LoopLineTheme.subtleStroke, lineWidth: 1)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            LoopLineSectionHeader(title: "About")

            VStack(alignment: .leading, spacing: 6) {
                Text("LoopLine")
                    .font(.headline)
                    .foregroundStyle(LoopLineTheme.primaryText)
                Text("Version \(viewModel.appVersion)")
                    .font(.subheadline)
                    .foregroundStyle(LoopLineTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous)
                    .stroke(LoopLineTheme.subtleStroke, lineWidth: 1)
            }
        }
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
                    .foregroundStyle(LoopLineTheme.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(LoopLineTheme.secondaryText)
            }
        }
        .padding(16)
        .tint(LoopLineTheme.accent)
    }
}

#Preview {
    let container = PreviewModelContainer.make()
    container.mainContext.insert(AppSettings())

    return SettingsView()
        .modelContainer(container)
}

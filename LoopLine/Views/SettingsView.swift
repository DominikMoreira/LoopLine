import Observation
import MessageUI
import SwiftData
import SwiftUI
import UIKit

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
    @Environment(\.openURL) private var openURL
    @Bindable var settings: AppSettings
    let viewModel: SettingsViewModel
    @State private var isShowingMailComposer = false
    @State private var isShowingMailUnavailableAlert = false

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
        .sheet(isPresented: $isShowingMailComposer) {
            FeedbackMailComposer(
                isPresented: $isShowingMailComposer,
                recipient: FeedbackConfiguration.feedbackEmailAddress,
                subject: String(
                    localized: "LoopLine – Product Improvement",
                    comment: "Subject line for an email suggesting an improvement to LoopLine."
                ),
                messageBody: viewModel.feedbackMailBody
            )
        }
        .alert("Mail is unavailable", isPresented: $isShowingMailUnavailableAlert) {
            Button("Copy email address") {
                UIPasteboard.general.string = FeedbackConfiguration.feedbackEmailAddress
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Set up Mail to send feedback, or email us at \(FeedbackConfiguration.feedbackEmailAddress).")
        }
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
                            Text("Text row highlight opacity")
                                .font(.headline)
                            Text("Customize the row highlight in text-imported projects")
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

                Divider()
                    .padding(.leading, 16)

                SettingsNavigationRow(title: "Privacy Policy") {
                    if let privacyPolicyURL = FeedbackConfiguration.privacyPolicyURL {
                        openURL(privacyPolicyURL)
                    }
                }

                Divider()
                    .padding(.leading, 16)

                SettingsNavigationRow(title: "Suggest an improvement") {
                    if MFMailComposeViewController.canSendMail() {
                        isShowingMailComposer = true
                    } else {
                        isShowingMailUnavailableAlert = true
                    }
                }
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
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
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

private struct SettingsNavigationRow: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(LoopLineTheme.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LoopLineTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let container = PreviewModelContainer.make()
    container.mainContext.insert(AppSettings())

    return SettingsView()
        .modelContainer(container)
}

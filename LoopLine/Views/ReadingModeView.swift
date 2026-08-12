import Observation
import SwiftData
import SwiftUI

struct ReadingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @Query private var settings: [AppSettings]
    @State private var viewModel = ReadingModeViewModel()

    private var appSettings: AppSettings {
        settings.first ?? AppSettings()
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    readingPanel
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, appSettings.largeControls ? 340 : 290)
            }
            .background(readingBackground.ignoresSafeArea())
            .navigationTitle("Reading Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(readingBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                Button {
                    viewModel.isShowingResetConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("Reset counters")
            }
            .safeAreaInset(edge: .bottom) {
                readingControls
            }
            .onAppear {
                viewModel.scrollToActiveRow(for: project, with: proxy)
            }
            .onChange(of: project.currentRow) { _, _ in
                viewModel.scrollToActiveRow(for: project, with: proxy)
            }
            .sheet(isPresented: $viewModel.isShowingAddNote) {
                AddNoteView(currentRow: project.currentRow) { draft in
                    viewModel.addNote(from: draft, to: project, in: modelContext)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .alert("Reset Counters?", isPresented: $viewModel.isShowingResetConfirmation) {
                Button("Reset", role: .destructive) {
                    viewModel.resetCounters(for: project, in: modelContext)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset the current row, repeat, and stitch to 1.")
            }
        }
    }

    private var readingPanel: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(panelBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(panelStroke, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 12) {
                if !project.rows.isEmpty {
                    rowContent
                } else if let sourceText = viewModel.trimmedSourceText(for: project) {
                    sourceTextContent(sourceText)
                } else {
                    emptyContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .frame(minHeight: 520)
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(project.rows.enumerated()), id: \.offset) { index, row in
                ReadingRow(
                    rowNumber: index + 1,
                    text: row,
                    isActive: index == viewModel.activeRowIndex(for: project),
                    usesLargeControls: appSettings.largeControls,
                    guideOpacity: appSettings.guideOpacity,
                    selectAction: {
                        viewModel.selectRow(at: index, in: project, modelContext: modelContext)
                    }
                )
                .id(index)
            }
        }
        .font(viewModel.readableFont(for: appSettings))
    }

    private func sourceTextContent(_ sourceText: String) -> some View {
        Text(sourceText)
            .font(viewModel.readableFont(for: appSettings))
            .foregroundStyle(primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }

    private var emptyContent: some View {
        ContentUnavailableView(
            "No Pattern Content",
            systemImage: "doc.text",
            description: Text("No pattern content is available yet.")
        )
        .foregroundStyle(primaryText)
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private var readingControls: some View {
        VStack(spacing: 12) {
            Divider()
                .overlay(dividerColor)

            CounterControlPanel(
                label: "ROW",
                value: String(project.currentRow),
                detail: viewModel.totalRows(for: project) > 0 ? "of \(viewModel.totalRows(for: project))" : nil,
                isPrimary: true,
                usesLargeControls: appSettings.largeControls,
                canDecrease: project.currentRow > 1,
                canIncrease: viewModel.canIncreaseRow(for: project),
                decreaseAction: { viewModel.decrementRow(for: project, in: modelContext) },
                increaseAction: { viewModel.incrementRow(for: project, in: modelContext) }
            )

            Divider()
                .overlay(dividerColor)

            CounterControlPanel(
                label: "REPEAT",
                value: String(project.repeatCurrent),
                detail: project.repeatTotal.map { "of \($0)" },
                isPrimary: false,
                usesLargeControls: appSettings.largeControls,
                canDecrease: project.repeatCurrent > 1,
                canIncrease: viewModel.canIncreaseRepeat(for: project),
                decreaseAction: { viewModel.decrementRepeat(for: project, in: modelContext) },
                increaseAction: { viewModel.incrementRepeat(for: project, in: modelContext) }
            )

            Divider()
                .overlay(dividerColor)

            CounterControlPanel(
                label: "STITCHES",
                value: String(project.currentStitch),
                detail: nil,
                isPrimary: false,
                usesLargeControls: appSettings.largeControls,
                canDecrease: project.currentStitch > 1,
                canIncrease: true,
                decreaseAction: { viewModel.decrementStitch(for: project, in: modelContext) },
                increaseAction: { viewModel.incrementStitch(for: project, in: modelContext) }
            )

            reminderStrip
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(readingBackground)
    }

    private var reminderStrip: some View {
        Button {
            viewModel.isShowingAddNote = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.yellow)

                Text(viewModel.reminderText(for: project))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)

                Spacer()

                Text("+ Add")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(stripBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(panelStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var readingBackground: Color {
        LoopLineTheme.readingBackground
    }

    private var panelBackground: Color {
        LoopLineTheme.readingPanel
    }

    private var panelStroke: Color {
        LoopLineTheme.readingStroke
    }

    private var primaryText: Color {
        LoopLineTheme.readingPrimaryText
    }

    private var secondaryText: Color {
        LoopLineTheme.readingSecondaryText
    }

    private var dividerColor: Color {
        LoopLineTheme.readingStroke
    }

    private var stripBackground: Color {
        LoopLineTheme.readingStripFill
    }
}

private struct ReadingRow: View {
    let rowNumber: Int
    let text: String
    let isActive: Bool
    let usesLargeControls: Bool
    let guideOpacity: Double
    let selectAction: () -> Void

    private var verticalPadding: CGFloat {
        usesLargeControls ? 12 : 8
    }

    private var horizontalPadding: CGFloat {
        usesLargeControls ? 12 : 10
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(rowNumber).")
                .fontWeight(isActive ? .bold : .regular)
                .foregroundStyle(rowNumberColor)
                .monospacedDigit()
                .frame(minWidth: 34, alignment: .trailing)

            Text(text)
                .foregroundStyle(rowTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.yellow.opacity(0.88 * guideOpacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: selectAction)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Sets this as the current row")
    }

    private var rowNumberColor: Color {
        isActive ? .black : LoopLineTheme.readingSecondaryText
    }

    private var rowTextColor: Color {
        isActive ? .black : LoopLineTheme.readingPrimaryText
    }
}

private struct CounterControlPanel: View {
    let label: String
    let value: String
    let detail: String?
    let isPrimary: Bool
    let usesLargeControls: Bool
    let canDecrease: Bool
    let canIncrease: Bool
    let decreaseAction: () -> Void
    let increaseAction: () -> Void

    private var buttonSize: CGFloat {
        if isPrimary {
            return usesLargeControls ? 76 : 62
        }
        return usesLargeControls ? 58 : 48
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(secondaryText)
                .frame(width: 72, alignment: .leading)

            Button(action: decreaseAction) {
                Image(systemName: "minus")
            }
            .buttonStyle(LoopLineIconButtonStyle(
                size: buttonSize,
                foregroundColor: primaryText,
                backgroundColor: secondaryButtonBackground
            ))
            .disabled(!canDecrease)
            .opacity(canDecrease ? 1 : 0.38)

            VStack(spacing: 1) {
                Text(value)
                    .font((isPrimary ? Font.system(size: 48, weight: .bold) : Font.system(size: 34, weight: .bold)).monospacedDigit())
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let detail {
                    Text(detail)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(secondaryText)
                }
            }
            .frame(minWidth: isPrimary ? 74 : 58)

            Button(action: increaseAction) {
                Image(systemName: "plus")
            }
            .buttonStyle(LoopLineIconButtonStyle(
                size: buttonSize,
                foregroundColor: primaryIncreaseForeground,
                backgroundColor: primaryIncreaseBackground
            ))
            .disabled(!canIncrease)
            .opacity(canIncrease ? 1 : 0.38)

            Spacer(minLength: 0)
        }
    }

    private var primaryText: Color {
        LoopLineTheme.readingPrimaryText
    }

    private var secondaryText: Color {
        LoopLineTheme.readingSecondaryText
    }

    private var secondaryButtonBackground: Color {
        LoopLineTheme.readingControlFill
    }

    private var primaryIncreaseForeground: Color {
        if isPrimary {
            return LoopLineTheme.primaryActionForeground
        }
        return primaryText
    }

    private var primaryIncreaseBackground: Color {
        if isPrimary {
            return LoopLineTheme.primaryActionBackground
        }
        return secondaryButtonBackground
    }
}

#Preview("Rows") {
    NavigationStack {
        ReadingModeView(project: Project(
            name: "Sample Scarf",
            sourceType: .text,
            currentRow: 2,
            rows: [
                "Cast on 24 stitches.",
                "Knit every stitch across the row.",
                "Turn and repeat until the scarf reaches the desired length."
            ]
        ))
    }
    .modelContainer(PreviewModelContainer.make())
}

#Preview("Source Text") {
    NavigationStack {
        ReadingModeView(project: Project(
            name: "Text Pattern",
            sourceType: .text,
            sourceText: "Cast on 24 stitches.\n\nKnit every row until the piece measures 48 inches. Bind off loosely."
        ))
    }
    .modelContainer(PreviewModelContainer.make())
}

#Preview("Empty") {
    NavigationStack {
        ReadingModeView(project: Project(
            name: "Empty Project",
            sourceType: .pdf
        ))
    }
    .modelContainer(PreviewModelContainer.make())
}

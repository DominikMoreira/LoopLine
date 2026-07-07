import SwiftData
import SwiftUI

struct ReadingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @Query private var settings: [AppSettings]
    @State private var isShowingAddNote = false
    @State private var isShowingResetConfirmation = false

    private var appSettings: AppSettings {
        settings.first ?? AppSettings()
    }

    private var trimmedSourceText: String? {
        guard let sourceText = project.sourceText?.trimmingCharacters(in: .whitespacesAndNewlines), !sourceText.isEmpty else {
            return nil
        }
        return sourceText
    }

    private var readableFont: Font {
        appSettings.largeControls ? .title3 : .body
    }

    private var totalRows: Int {
        project.rows.count
    }

    private var activeRowIndex: Int? {
        guard !project.rows.isEmpty else { return nil }
        return min(max(project.currentRow, 1), project.rows.count) - 1
    }

    private var currentRowNotes: [ProjectNote] {
        project.notes.filter { $0.rowNumber == project.currentRow }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    readingPanel
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, appSettings.largeControls ? 260 : 220)
            }
            .background(readingBackground.ignoresSafeArea())
            .navigationTitle("Reading Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(readingBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                Button {
                    isShowingResetConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("Reset counters")
            }
            .safeAreaInset(edge: .bottom) {
                readingControls
            }
            .onAppear {
                scrollToActiveRow(with: proxy)
            }
            .onChange(of: project.currentRow) { _, _ in
                scrollToActiveRow(with: proxy)
            }
            .sheet(isPresented: $isShowingAddNote) {
                AddNoteView(currentRow: project.currentRow) { draft in
                    addNote(from: draft)
                    isShowingAddNote = false
                }
                .presentationDetents([.medium, .large])
            }
            .alert("Reset Counters?", isPresented: $isShowingResetConfirmation) {
                Button("Reset", role: .destructive) {
                    resetCounters()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset the current row and repeat to 1.")
            }
        }
    }

    private var readingPanel: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.12, green: 0.16, blue: 0.23))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }

            Rectangle()
                .fill(Color.blue.opacity(0.62 * appSettings.guideOpacity))
                .frame(width: 2)
                .padding(.leading, 210)
                .padding(.vertical, 1)

            VStack(alignment: .leading, spacing: 12) {
                if !project.rows.isEmpty {
                    rowContent
                } else if let trimmedSourceText {
                    sourceTextContent(trimmedSourceText)
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
                    isActive: index == activeRowIndex,
                    usesLargeControls: appSettings.largeControls,
                    guideOpacity: appSettings.guideOpacity,
                    selectAction: {
                        selectRow(at: index)
                    }
                )
                .id(index)
            }
        }
        .font(readableFont)
    }

    private func sourceTextContent(_ sourceText: String) -> some View {
        Text(sourceText)
            .font(readableFont)
            .foregroundStyle(.white.opacity(0.88))
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
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private var readingControls: some View {
        VStack(spacing: 12) {
            Divider()
                .overlay(Color.white.opacity(0.14))

            CounterControlPanel(
                label: "ROW",
                value: String(project.currentRow),
                detail: totalRows > 0 ? "of \(totalRows)" : nil,
                isPrimary: true,
                usesLargeControls: appSettings.largeControls,
                canDecrease: project.currentRow > 1,
                canIncrease: canIncreaseRow,
                decreaseAction: decrementRow,
                increaseAction: incrementRow
            )

            Divider()
                .overlay(Color.white.opacity(0.14))

            CounterControlPanel(
                label: "REPEAT",
                value: String(project.repeatCurrent),
                detail: project.repeatTotal.map { "of \($0)" },
                isPrimary: false,
                usesLargeControls: appSettings.largeControls,
                canDecrease: project.repeatCurrent > 1,
                canIncrease: canIncreaseRepeat,
                decreaseAction: decrementRepeat,
                increaseAction: incrementRepeat
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
            isShowingAddNote = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.yellow)

                Text(reminderText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                Spacer()

                Text("+ Add")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var reminderText: String {
        if let note = currentRowNotes.first {
            return "Row \(project.currentRow) - \(note.text)"
        }
        return "Row \(project.currentRow) - no reminders"
    }

    private var canIncreaseRow: Bool {
        totalRows == 0 || project.currentRow < totalRows
    }

    private var canIncreaseRepeat: Bool {
        guard let repeatTotal = project.repeatTotal else { return true }
        return project.repeatCurrent < repeatTotal
    }

    private var readingBackground: Color {
        Color(red: 0.06, green: 0.09, blue: 0.14)
    }

    private func selectRow(at index: Int) {
        guard project.rows.indices.contains(index) else { return }
        project.currentRow = index + 1
        saveChanges()
    }

    private func incrementRow() {
        guard canIncreaseRow else { return }
        project.currentRow += 1
        saveChanges()
    }

    private func decrementRow() {
        guard project.currentRow > 1 else { return }
        project.currentRow -= 1
        saveChanges()
    }

    private func incrementRepeat() {
        guard canIncreaseRepeat else { return }
        project.repeatCurrent += 1
        saveChanges()
    }

    private func decrementRepeat() {
        guard project.repeatCurrent > 1 else { return }
        project.repeatCurrent -= 1
        saveChanges()
    }

    private func resetCounters() {
        project.currentRow = 1
        project.repeatCurrent = 1
        saveChanges()
    }

    private func addNote(from draft: NoteDraft) {
        let note = ProjectNote(
            text: draft.trimmedText,
            rowNumber: draft.rowNumber
        )

        modelContext.insert(note)
        project.notes.append(note)
        saveChanges()
    }

    private func saveChanges() {
        try? modelContext.save()
    }

    private func scrollToActiveRow(with proxy: ScrollViewProxy) {
        guard let activeRowIndex else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(activeRowIndex, anchor: .center)
        }
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
                .foregroundStyle(isActive ? .black : .white.opacity(0.42))
                .monospacedDigit()
                .frame(minWidth: 34, alignment: .trailing)

            Text(text)
                .foregroundStyle(isActive ? .black : .white.opacity(0.72))
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
                .foregroundStyle(.white.opacity(0.48))
                .frame(width: 72, alignment: .leading)

            Button(action: decreaseAction) {
                Image(systemName: "minus")
            }
            .buttonStyle(LoopLineIconButtonStyle(
                size: buttonSize,
                foregroundColor: .white,
                backgroundColor: Color.white.opacity(0.14)
            ))
            .disabled(!canDecrease)
            .opacity(canDecrease ? 1 : 0.38)

            VStack(spacing: 1) {
                Text(value)
                    .font((isPrimary ? Font.system(size: 48, weight: .bold) : Font.system(size: 34, weight: .bold)).monospacedDigit())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let detail {
                    Text(detail)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
            .frame(minWidth: isPrimary ? 74 : 58)

            Button(action: increaseAction) {
                Image(systemName: "plus")
            }
            .buttonStyle(LoopLineIconButtonStyle(
                size: buttonSize,
                foregroundColor: isPrimary ? .black : .white,
                backgroundColor: isPrimary ? .white : Color.white.opacity(0.14)
            ))
            .disabled(!canIncrease)
            .opacity(canIncrease ? 1 : 0.38)

            Spacer(minLength: 0)
        }
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

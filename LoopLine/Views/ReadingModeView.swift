import Observation
import SwiftData
import SwiftUI

struct ReadingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @Query private var settings: [AppSettings]
    @State private var viewModel = ReadingModeViewModel()
    @State private var noteToEdit: ProjectNote?
    @State private var notePendingDeletion: ProjectNote?

    private var appSettings: AppSettings {
        settings.first ?? AppSettings()
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ReadingTrackingControls(
                    project: project,
                    usesLargeControls: appSettings.largeControls
                )
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        readingPanel
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }
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
                reminderControls
            }
            .onAppear {
                DispatchQueue.main.async {
                    viewModel.scrollToActiveRow(for: project, with: proxy)
                }
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
            .sheet(item: $noteToEdit) { note in
                AddNoteView(note: note) { draft in
                    viewModel.updateNote(note, from: draft, in: modelContext)
                    noteToEdit = nil
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .alert("Delete Note?", isPresented: deleteNoteConfirmationBinding) {
                Button("Delete Note", role: .destructive) {
                    if let notePendingDeletion {
                        viewModel.deleteNote(notePendingDeletion, in: modelContext)
                    }
                    notePendingDeletion = nil
                }
                Button("Cancel", role: .cancel) {
                    notePendingDeletion = nil
                }
            } message: {
                Text("This will permanently delete this note. This cannot be undone.")
            }
            .alert("Reset Counters?", isPresented: $viewModel.isShowingResetConfirmation) {
                Button("Reset", role: .destructive) {
                    viewModel.resetCounters(for: project, in: modelContext)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset the current row, repeat, and stitch to 0.")
            }
        }
    }

    private var readingPanel: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous)
                .fill(panelBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous)
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
                    rowNumber: index,
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

    private var reminderControls: some View {
        VStack(spacing: 12) {
            Divider()
                .overlay(dividerColor)

            reminderStrip
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(LoopLineTheme.surface.shadow(color: LoopLineTheme.shadow, radius: 16, x: 0, y: -6))
    }

    private var reminderStrip: some View {
        let notes = viewModel.currentRowNotes(for: project)

        return HStack(spacing: 10) {
            Image(systemName: "flag.fill")
                .foregroundStyle(LoopLineTheme.readingGuide)

            Text(viewModel.reminderText(for: project))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)
                .lineLimit(1)

            Spacer()

            if !notes.isEmpty {
                Menu {
                    ForEach(notes) { note in
                        Menu {
                            Button("Edit", systemImage: "pencil") {
                                noteToEdit = note
                            }
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                notePendingDeletion = note
                            }
                        } label: {
                            Text(note.text)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 32, height: 44)
                }
                .accessibilityLabel("Note actions")
            }

            Button("+ Add") {
                viewModel.isShowingAddNote = true
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(LoopLineTheme.accent)
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(stripBackground, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        }
    }

    private var deleteNoteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { notePendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    notePendingDeletion = nil
                }
            }
        )
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
                RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous)
                    .fill(LoopLineTheme.readingGuide.opacity(0.84 * guideOpacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: selectAction)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Sets this as the current row")
    }

    private var rowNumberColor: Color {
        isActive ? LoopLineTheme.primaryText : LoopLineTheme.readingSecondaryText
    }

    private var rowTextColor: Color {
        isActive ? LoopLineTheme.primaryText : LoopLineTheme.readingPrimaryText
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

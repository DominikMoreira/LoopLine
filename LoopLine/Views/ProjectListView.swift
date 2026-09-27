import Observation
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var viewModel = ProjectListViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(spacing: 0) {
                header

                if projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .background(LoopLineTheme.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.isShowingCreateProject) {
                CreateProjectView { draft in
                    try viewModel.createProject(from: draft, in: modelContext)
                }
            }
            .alert("Delete Project?", isPresented: $viewModel.isShowingDeleteConfirmation) {
                Button("Delete Project", role: .destructive) {
                    viewModel.confirmProjectDeletion(in: modelContext)
                }
                Button("Cancel", role: .cancel) {
                    viewModel.projectPendingDeletion = nil
                }
            } message: {
                Text(viewModel.deleteConfirmationMessage)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Projects")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                viewModel.showCreateProject()
            } label: {
                Label("New", systemImage: "plus")
                    .font(.headline)
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain)
            .foregroundStyle(LoopLineTheme.accent)
            .frame(minHeight: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(LoopLineTheme.separator)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 120)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LoopLineTheme.accentSoft)
                    .frame(width: 112, height: 112)

                Image(systemName: "doc.badge.plus")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(LoopLineTheme.accent)
            }

            VStack(spacing: 8) {
                Text("No projects yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(LoopLineTheme.primaryText)

                Text("Add your first knitting pattern - from a PDF, photo, or pasted text.")
                    .font(.body)
                    .foregroundStyle(LoopLineTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                viewModel.showCreateProject()
            } label: {
                Text("Create project")
            }
            .buttonStyle(LoopLinePrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.top, 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var projectList: some View {
        List(projects) { project in
            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                ProjectCard(project: project)
            }
            .modifier(UITestPDFProjectIdentifier(projectName: project.name))
            .listRowInsets(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 18))
            .listRowSeparator(.visible)
            .listRowBackground(LoopLineTheme.appBackground)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Delete Project", role: .destructive) {
                    viewModel.requestDeletion(for: project)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .accessibilityIdentifier("projectsList")
    }
}

private struct UITestPDFProjectIdentifier: ViewModifier {
    let projectName: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if projectName == "UI Test PDF Project" {
            content.accessibilityIdentifier("uiTestPDFProject")
        } else {
            content
        }
    }
}

private struct ProjectCard: View {
    let project: Project

    private var totalRows: Int {
        project.rows.count
    }

    private var progress: Double? {
        guard totalRows > 0 else { return nil }
        let maxRowIndex = totalRows - 1
        let clampedRow = min(max(project.currentRow, 0), maxRowIndex)
        guard maxRowIndex > 0 else { return 1 }
        return Double(clampedRow) / Double(maxRowIndex)
    }

    var body: some View {
        HStack(spacing: 16) {
            thumbnail
                .frame(width: 74, height: 74)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(project.name)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(LoopLineTheme.primaryText)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        LoopLineSourceBadge(sourceType: project.sourceType)
                    }

                    Text(metricSummary)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(LoopLineTheme.secondaryText)
                        .lineLimit(1)
                }

                LoopLineProgressBar(progress: progress)
                    .frame(maxWidth: .infinity)
            }
        }
        .contentShape(Rectangle())
    }

    private var metricSummary: String {
        let repeatText = project.repeatTotal.map { "\(project.repeatCurrent)/\($0)" } ?? String(project.repeatCurrent)
        return String(localized: "Row \(project.currentRow)  x \(repeatText)  \(project.currentStitch) sts")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if project.sourceType == .pdf, let sourceFilePath = project.sourceFilePath {
            StoredPDFPreview(storedReference: sourceFilePath, height: 74)
                .frame(width: 74, height: 74)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous)
                        .stroke(LoopLineTheme.subtleStroke, lineWidth: 1)
                }
        } else if project.sourceType == .image, let sourceFilePath = project.sourceFilePath {
            StoredImagePreview(storedReference: sourceFilePath, height: 74)
                .frame(width: 74, height: 74)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous)
                        .stroke(LoopLineTheme.subtleStroke, lineWidth: 1)
                }
        } else {
            LoopLineSourcePlaceholder(sourceType: project.sourceType)
        }
    }
}

private struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateProjectViewModel()

    let onCreate: (NewProjectDraft) throws -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    projectInfoSection
                    patternSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 110)
            }
            .background(LoopLineTheme.appBackground.ignoresSafeArea())
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cleanupDraftFiles()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    viewModel.createProject(using: onCreate)
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(LoopLineTheme.primaryActionForeground)
                            .accessibilityLabel("Creating project")
                    } else {
                        Text("Create Project")
                    }
                }
                .buttonStyle(LoopLinePrimaryButtonStyle())
                .disabled(!viewModel.canCreateProject)
                .opacity(viewModel.canCreateProject ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
            .sheet(isPresented: $viewModel.isShowingTextEditor) {
                PastedTextImportView(initialText: viewModel.draft.sourceText) { text in
                    viewModel.savePatternText(text)
                }
            }
            .fileImporter(
                isPresented: $viewModel.isShowingPDFImporter,
                allowedContentTypes: [.pdf]
            ) { result in
                viewModel.importPDF(from: result)
            }
            .photosPicker(
                isPresented: $viewModel.isShowingPhotoPicker,
                selection: $viewModel.selectedImageItem,
                matching: .images
            )
            .onChange(of: viewModel.selectedImageItem) { _, newItem in
                viewModel.importImage(from: newItem)
            }
            .confirmationDialog("Replace Pattern", isPresented: $viewModel.isShowingReplacementOptions) {
                Button("Import PDF") {
                    viewModel.showPDFImporter()
                }
                Button("Choose Photo") {
                    viewModel.showPhotoPicker()
                }
                Button("Write or Paste Text") {
                    viewModel.showTextEditor()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose a new pattern source. Your current pattern stays in place until the replacement succeeds.")
            }
            .onDisappear {
                viewModel.cleanupDraftFilesIfNeeded()
            }
        }
    }

    private var projectInfoSection: some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 16) {
            LoopLineFieldLabel(text: "Project title")
            TextField("Aran Cable Sweater", text: $viewModel.draft.name)
                .font(.title3)
                .textFieldStyle(.plain)
                .padding(18)
                .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous)
                        .stroke(LoopLineTheme.subtleStroke, lineWidth: 1)
                }

            LoopLineFieldLabel(text: "Subtitle")
            TextField("Size, yarn, or recipient", text: $viewModel.draft.subtitle)
                .font(.body)
                .textFieldStyle(.plain)
                .padding(16)
                .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
        }
    }

    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LoopLineSectionHeader(title: "Add a pattern")

            if viewModel.draft.sourceType == nil {
                importActions
            } else {
                selectedSourcePreview
            }

            if viewModel.isImportingPDF {
                ProgressView("Importing PDF…")
            } else if viewModel.isImportingImage {
                ProgressView("Importing photo…")
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(LoopLineTheme.destructive)
                    .accessibilityLabel("Error: \(errorMessage)")
            }
        }
    }

    private var importActions: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.showPDFImporter()
            } label: {
                PatternImportAction(
                    title: "Import PDF",
                    description: "Choose a PDF from Files",
                    systemImage: "doc.fill"
                )
            }
            .buttonStyle(.plain)

            Button {
                viewModel.showPhotoPicker()
            } label: {
                PatternImportAction(
                    title: "Choose Photo",
                    description: "Select one photo or screenshot",
                    systemImage: "photo"
                )
            }
            .buttonStyle(.plain)

            Button {
                viewModel.showTextEditor()
            } label: {
                PatternImportAction(
                    title: "Write or Paste Text",
                    description: "Enter pattern instructions",
                    systemImage: "text.alignleft"
                )
            }
            .buttonStyle(.plain)
        }
        .disabled(viewModel.isImportingPDF || viewModel.isImportingImage)
    }

    private var selectedSourcePreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                sourcePreview
                sourceSummary
                Spacer(minLength: 0)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    previewActions
                }
                VStack(spacing: 8) {
                    previewActions
                }
            }
        }
        .padding(16)
        .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous)
                .stroke(LoopLineTheme.subtleStroke, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var sourcePreview: some View {
        if viewModel.draft.sourceType == .image, let imagePath = viewModel.draft.imageFilePath {
            StoredImagePreview(storedReference: imagePath, height: 72)
                .frame(width: 72, height: 72)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
                .accessibilityLabel("Selected pattern photo")
        } else {
            Image(systemName: viewModel.draft.sourceType == .pdf ? "doc.fill" : "text.alignleft")
                .font(.title2.weight(.semibold))
                .foregroundStyle(LoopLineTheme.accent)
                .frame(width: 56, height: 56)
                .background(LoopLineTheme.accentSoft, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
                .accessibilityHidden(true)
        }
    }

    private var sourceSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sourceTitle)
                .font(.headline)
                .foregroundStyle(LoopLineTheme.primaryText)
            Text(sourceDetail)
                .font(.subheadline)
                .foregroundStyle(LoopLineTheme.secondaryText)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var previewActions: some View {
        Button {
            viewModel.isShowingReplacementOptions = true
        } label: {
            Label("Replace", systemImage: "arrow.triangle.2.circlepath")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Replace selected pattern")

        Button(role: .destructive) {
            viewModel.removeSelectedSource()
        } label: {
            Label("Remove", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Remove selected pattern")
    }

    private var sourceTitle: LocalizedStringResource {
        switch viewModel.draft.sourceType {
        case .pdf: "PDF"
        case .image: "Photo"
        case .text: "Pattern text added"
        case nil: "Add a pattern"
        }
    }

    private var sourceDetail: String {
        switch viewModel.draft.sourceType {
        case .pdf:
            viewModel.draft.sourceFileName ?? String(localized: "PDF selected")
        case .image:
            String(localized: "Photo selected")
        case .text:
            String(localized: "\(viewModel.draft.trimmedSourceText.count) characters")
        case nil:
            ""
        }
    }
}

private struct PatternImportAction: View {
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(LoopLineTheme.accent)
                .frame(width: 44, height: 44)
                .background(LoopLineTheme.accentSoft, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(LoopLineTheme.primaryText)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(LoopLineTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LoopLineTheme.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous)
                .stroke(LoopLineTheme.subtleStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Empty") {
    ProjectListView()
        .modelContainer(PreviewModelContainer.make())
}

#Preview("With Project") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    context.insert(Project(
        name: "Sample Scarf",
        subtitle: "Beginner garter stitch",
        sourceType: .text,
        currentRow: 2,
        repeatCurrent: 0,
        repeatTotal: 4,
        rows: ["Cast on", "Knit", "Bind off"]
    ))

    return ProjectListView()
        .modelContainer(container)
}

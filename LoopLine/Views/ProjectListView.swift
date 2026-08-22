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
            .background(LoopLineTheme.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.isShowingCreateProject) {
                CreateProjectView { draft in
                    viewModel.createProject(from: draft, in: modelContext)
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
            .buttonStyle(LoopLinePrimaryButtonStyle(isFullWidth: false))
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 120)

            ZStack {
                Circle()
                    .fill(LoopLineTheme.surface)
                    .frame(width: 112, height: 112)
                    .overlay {
                        Circle()
                            .stroke(Color.secondary.opacity(0.32), lineWidth: 1)
                    }

                Image(systemName: "sparkle")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("No projects yet")
                    .font(.title3.weight(.bold))

                Text("Add a pattern to get started - from a PDF, photo, or pasted text.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                viewModel.showCreateProject()
            } label: {
                Label("Create first project", systemImage: "plus")
                    .labelStyle(.titleAndIcon)
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
            .listRowInsets(EdgeInsets(top: 18, leading: 24, bottom: 18, trailing: 18))
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

    private var rowSummary: String {
        if totalRows > 0 {
            let clampedRow = min(max(project.currentRow, 0), totalRows - 1)
            return "Row \(clampedRow)/\(totalRows)"
        }

        return "Row \(max(project.currentRow, 0))"
    }

    var body: some View {
        HStack(spacing: 16) {
            thumbnail
                .frame(width: 74, height: 74)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(project.subtitle?.isEmpty == false ? project.subtitle ?? "" : project.sourceType.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 14) {
                    LoopLineProgressBar(progress: progress)
                        .frame(maxWidth: .infinity)

                    Text(rowSummary)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnail: some View {
        if project.sourceType == .pdf, let sourceFilePath = project.sourceFilePath {
            StoredPDFPreview(storedReference: sourceFilePath, height: 74)
                .frame(width: 74, height: 74)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                }
        } else if project.sourceType == .image, let sourceFilePath = project.sourceFilePath {
            StoredImagePreview(storedReference: sourceFilePath, height: 74)
                .frame(width: 74, height: 74)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                }
        } else {
            LoopLineSourcePlaceholder(sourceType: project.sourceType)
        }
    }
}

private struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateProjectViewModel()

    let onCreate: (NewProjectDraft) -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    projectInfoSection
                    stepIndicator
                    sourceSelectionSection
                    selectedSourceSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 110)
            }
            .background(LoopLineTheme.appBackground)
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
                    viewModel.markCreated()
                    onCreate(viewModel.draft)
                } label: {
                    Text("Create Project")
                }
                .buttonStyle(LoopLinePrimaryButtonStyle())
                .disabled(!viewModel.canCreateProject)
                .opacity(viewModel.canCreateProject ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
            .sheet(isPresented: $viewModel.isShowingTextImport) {
                PastedTextImportView(initialText: viewModel.draft.sourceText) { text in
                    viewModel.setPastedText(text)
                }
            }
            .fileImporter(
                isPresented: $viewModel.isShowingPDFImporter,
                allowedContentTypes: [.pdf]
            ) { result in
                viewModel.importPDF(from: result)
            }
            .onChange(of: viewModel.selectedImageItem) { _, newItem in
                viewModel.importImage(from: newItem)
            }
            .onDisappear {
                viewModel.cleanupDraftFilesIfNeeded()
            }
        }
    }

    private var projectInfoSection: some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 16) {
            LoopLineFieldLabel(text: "Project name")
            TextField("Aran Cable Sweater", text: $viewModel.draft.name)
                .font(.title3)
                .textFieldStyle(.plain)
                .padding(18)
                .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.42), lineWidth: 1)
                }

            LoopLineFieldLabel(text: "Subtitle")
            TextField("Size, yarn, or recipient", text: $viewModel.draft.subtitle)
                .font(.body)
                .textFieldStyle(.plain)
                .padding(16)
                .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 10) {
            Capsule()
                .fill(LoopLineTheme.primaryActionBackground)
                .frame(width: 38, height: 8)
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 38, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var sourceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LoopLineSectionHeader(title: "Add Pattern")

            ForEach(ImportSource.allCases, id: \.self) { sourceType in
                Button {
                    viewModel.selectSourceType(sourceType)
                } label: {
                    SourceOptionRow(
                        sourceType: sourceType,
                        isSelected: viewModel.draft.sourceType == sourceType
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var selectedSourceSection: some View {
        @Bindable var viewModel = viewModel

        switch viewModel.draft.sourceType {
        case .text:
            VStack(alignment: .leading, spacing: 12) {
                Button(viewModel.draft.trimmedSourceText.isEmpty ? "Enter Pasted Text" : "Edit Pasted Text") {
                    viewModel.isShowingTextImport = true
                }
                .buttonStyle(LoopLineSecondaryButtonStyle())

                Text(viewModel.draft.rows.isEmpty ? "Pattern text is required for pasted text projects." : "\(viewModel.draft.rows.count) rows ready to import")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .pdf:
            VStack(alignment: .leading, spacing: 12) {
                Button(viewModel.draft.sourceFileName == nil ? "Choose PDF" : "Choose Different PDF") {
                    viewModel.showPDFImporter()
                }
                .buttonStyle(LoopLineSecondaryButtonStyle())

                sourceStatus(
                    fileName: viewModel.draft.sourceFileName,
                    emptyText: "A PDF is required for PDF projects.",
                    errorText: viewModel.pdfImportError,
                    iconName: "doc.richtext"
                )
            }
        case .image:
            let imageButtonTitle = viewModel.draft.imageFileName == nil ? "Choose Image" : "Choose Different Image"

            VStack(alignment: .leading, spacing: 12) {
                PhotosPicker(
                    selection: Binding(
                        get: { viewModel.selectedImageItem },
                        set: { viewModel.selectedImageItem = $0 }
                    ),
                    matching: .images
                ) {
                    Text(imageButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LoopLineSecondaryButtonStyle())
                .disabled(viewModel.isImportingImage)

                if viewModel.isImportingImage {
                    ProgressView("Importing image...")
                } else if let imageFilePath = viewModel.draft.imageFilePath {
                    StoredImagePreview(storedReference: imageFilePath, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    sourceStatus(
                        fileName: viewModel.draft.imageFileName,
                        emptyText: "An image is required for image projects.",
                        errorText: viewModel.imageImportError,
                        iconName: "photo"
                    )
                } else {
                    sourceStatus(
                        fileName: nil,
                        emptyText: "An image is required for image projects.",
                        errorText: viewModel.imageImportError,
                        iconName: "photo"
                    )
                }
            }
        }
    }

    private func sourceStatus(fileName: String?, emptyText: String, errorText: String?, iconName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let fileName {
                Label(fileName, systemImage: iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text(emptyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct SourceOptionRow: View {
    let sourceType: ImportSource
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSelected ? LoopLineTheme.primaryActionForeground : .primary)
                .frame(width: 44, height: 44)
                .background(isSelected ? LoopLineTheme.primaryActionBackground : LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(sourceType.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? LoopLineTheme.primaryActionBackground : Color.secondary.opacity(0.4))
        }
        .padding(14)
        .background(LoopLineTheme.appBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? LoopLineTheme.primaryActionBackground : Color.secondary.opacity(0.24), lineWidth: isSelected ? 1.5 : 1)
        }
    }

    private var iconName: String {
        switch sourceType {
        case .pdf:
            "doc.richtext"
        case .image:
            "photo"
        case .text:
            "text.alignleft"
        }
    }

    private var description: String {
        switch sourceType {
        case .pdf:
            "Import a saved pattern PDF."
        case .image:
            "Use a photo or screenshot."
        case .text:
            "Paste plain pattern text."
        }
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

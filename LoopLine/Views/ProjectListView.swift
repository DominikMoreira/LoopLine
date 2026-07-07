import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]
    @State private var isShowingCreateProject = false
    @State private var projectPendingDeletion: Project?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingCreateProject) {
                CreateProjectView { draft in
                    createProject(from: draft)
                    isShowingCreateProject = false
                }
            }
            .alert("Delete Project?", isPresented: deleteConfirmationBinding) {
                Button("Delete Project", role: .destructive) {
                    confirmProjectDeletion()
                }
                Button("Cancel", role: .cancel) {
                    projectPendingDeletion = nil
                }
            } message: {
                Text(deleteConfirmationMessage)
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
                isShowingCreateProject = true
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
                    .fill(Color(.secondarySystemBackground))
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
                isShowingCreateProject = true
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

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { projectPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    projectPendingDeletion = nil
                }
            }
        )
    }

    private var deleteConfirmationMessage: String {
        guard let projectPendingDeletion else {
            return "This will permanently delete this project and its notes. This cannot be undone."
        }

        return "This will permanently delete \(projectPendingDeletion.name) and its notes. This cannot be undone."
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
            .listRowBackground(Color(.systemBackground))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Delete Project", role: .destructive) {
                    projectPendingDeletion = project
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func createProject(from draft: NewProjectDraft) {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSubtitle = draft.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSourceText = draft.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)

        let project = Project(
            name: trimmedName,
            subtitle: trimmedSubtitle.isEmpty ? nil : trimmedSubtitle,
            sourceType: draft.sourceType,
            currentRow: 1,
            repeatCurrent: 1,
            repeatTotal: nil,
            rows: draft.sourceType == .text ? draft.rows : [],
            sourceText: draft.sourceType == .text && !trimmedSourceText.isEmpty ? trimmedSourceText : nil,
            sourceFilePath: sourceFilePath(from: draft),
            notes: []
        )

        modelContext.insert(project)
    }

    private func sourceFilePath(from draft: NewProjectDraft) -> String? {
        switch draft.sourceType {
        case .pdf:
            draft.sourceFilePath
        case .image:
            draft.imageFilePath
        case .text:
            nil
        }
    }

    private func confirmProjectDeletion() {
        guard let project = projectPendingDeletion else { return }
        projectPendingDeletion = nil
        deleteProject(project)
    }

    private func deleteProject(_ project: Project) {
        if project.sourceType == .pdf {
            ImportedPDFStorage.delete(storedReference: project.sourceFilePath)
        } else if project.sourceType == .image {
            ImportedImageStorage.delete(storedReference: project.sourceFilePath)
        }

        modelContext.delete(project)
        try? modelContext.save()
    }
}

private struct ProjectCard: View {
    let project: Project

    private var totalRows: Int {
        project.rows.count
    }

    private var progress: Double? {
        guard totalRows > 0 else { return nil }
        let clampedRow = min(max(project.currentRow, 1), totalRows)
        return Double(clampedRow) / Double(totalRows)
    }

    private var rowSummary: String {
        totalRows > 0 ? "Row  \(project.currentRow)/\(totalRows)" : "Row  \(project.currentRow)"
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
        if project.sourceType == .image, let sourceFilePath = project.sourceFilePath {
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

private struct NewProjectDraft {
    var name = ""
    var subtitle = ""
    var sourceType: ImportSource = .text
    var sourceText = ""
    var sourceFilePath: String?
    var sourceFileName: String?
    var imageFilePath: String?
    var imageFileName: String?
    var rows: [String] = []

    var trimmedSourceText: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasName && hasRequiredSource
    }

    private var hasRequiredSource: Bool {
        switch sourceType {
        case .text:
            !trimmedSourceText.isEmpty
        case .pdf:
            sourceFilePath != nil
        case .image:
            imageFilePath != nil
        }
    }

    mutating func setPastedText(_ text: String) {
        sourceText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        rows = PatternTextNormalizer.rows(from: sourceText)
    }

    mutating func clearPastedText() {
        sourceText = ""
        rows = []
    }

    mutating func setPDF(path: String, fileName: String) {
        sourceFilePath = path
        sourceFileName = fileName
    }

    mutating func clearPDF() {
        sourceFilePath = nil
        sourceFileName = nil
    }

    mutating func setImage(path: String, fileName: String) {
        imageFilePath = path
        imageFileName = fileName
    }

    mutating func clearImage() {
        imageFilePath = nil
        imageFileName = nil
    }
}

private struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = NewProjectDraft()
    @State private var isShowingTextImport = false
    @State private var isShowingPDFImporter = false
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var pdfImportError: String?
    @State private var imageImportError: String?
    @State private var isImportingImage = false

    let onCreate: (NewProjectDraft) -> Void

    var body: some View {
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
            .background(Color(.systemBackground))
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onCreate(draft)
                } label: {
                    Text("Create Project")
                }
                .buttonStyle(LoopLinePrimaryButtonStyle())
                .disabled(!draft.isValid || isImportingImage)
                .opacity((draft.isValid && !isImportingImage) ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
            .sheet(isPresented: $isShowingTextImport) {
                PastedTextImportView(initialText: draft.sourceText) { text in
                    draft.setPastedText(text)
                    isShowingTextImport = false
                }
            }
            .fileImporter(
                isPresented: $isShowingPDFImporter,
                allowedContentTypes: [.pdf]
            ) { result in
                importPDF(from: result)
            }
            .onChange(of: selectedImageItem) { _, newItem in
                importImage(from: newItem)
            }
        }
    }

    private var projectInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LoopLineFieldLabel(text: "Project name")
            TextField("Aran Cable Sweater", text: $draft.name)
                .font(.title3)
                .textFieldStyle(.plain)
                .padding(18)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.42), lineWidth: 1)
                }

            LoopLineFieldLabel(text: "Subtitle")
            TextField("Size, yarn, or recipient", text: $draft.subtitle)
                .font(.body)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 10) {
            Capsule()
                .fill(Color.primary)
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
                    draft.sourceType = sourceType
                    handleSourceTypeChange(sourceType)
                } label: {
                    SourceOptionRow(
                        sourceType: sourceType,
                        isSelected: draft.sourceType == sourceType
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var selectedSourceSection: some View {
        switch draft.sourceType {
        case .text:
            VStack(alignment: .leading, spacing: 12) {
                Button(draft.trimmedSourceText.isEmpty ? "Enter Pasted Text" : "Edit Pasted Text") {
                    isShowingTextImport = true
                }
                .buttonStyle(LoopLineSecondaryButtonStyle())

                Text(draft.rows.isEmpty ? "Pattern text is required for pasted text projects." : "\(draft.rows.count) rows ready to import")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .pdf:
            VStack(alignment: .leading, spacing: 12) {
                Button(draft.sourceFileName == nil ? "Choose PDF" : "Choose Different PDF") {
                    pdfImportError = nil
                    isShowingPDFImporter = true
                }
                .buttonStyle(LoopLineSecondaryButtonStyle())

                sourceStatus(
                    fileName: draft.sourceFileName,
                    emptyText: "A PDF is required for PDF projects.",
                    errorText: pdfImportError,
                    iconName: "doc.richtext"
                )
            }
        case .image:
            VStack(alignment: .leading, spacing: 12) {
                PhotosPicker(
                    selection: $selectedImageItem,
                    matching: .images
                ) {
                    Text(draft.imageFileName == nil ? "Choose Image" : "Choose Different Image")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LoopLineSecondaryButtonStyle())
                .disabled(isImportingImage)

                if isImportingImage {
                    ProgressView("Importing image...")
                } else if let imageFilePath = draft.imageFilePath {
                    StoredImagePreview(storedReference: imageFilePath, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    sourceStatus(
                        fileName: draft.imageFileName,
                        emptyText: "An image is required for image projects.",
                        errorText: imageImportError,
                        iconName: "photo"
                    )
                } else {
                    sourceStatus(
                        fileName: nil,
                        emptyText: "An image is required for image projects.",
                        errorText: imageImportError,
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

    private func importPDF(from result: Result<URL, Error>) {
        do {
            let sourceURL = try result.get()
            let localURL = try ImportedPDFStorage.copyIntoStorage(from: sourceURL)
            ImportedPDFStorage.delete(storedReference: draft.sourceFilePath)
            draft.setPDF(path: localURL.lastPathComponent, fileName: localURL.lastPathComponent)
            pdfImportError = nil
        } catch {
            pdfImportError = "Could not import the selected PDF."
        }
    }

    private func importImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        isImportingImage = true
        imageImportError = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw CocoaError(.fileReadCorruptFile)
                }

                let localURL = try ImportedImageStorage.saveImageData(data)
                await MainActor.run {
                    guard draft.sourceType == .image else {
                        ImportedImageStorage.delete(storedReference: localURL.lastPathComponent)
                        selectedImageItem = nil
                        isImportingImage = false
                        return
                    }

                    ImportedImageStorage.delete(storedReference: draft.imageFilePath)
                    draft.setImage(path: localURL.lastPathComponent, fileName: localURL.lastPathComponent)
                    selectedImageItem = nil
                    isImportingImage = false
                }
            } catch {
                await MainActor.run {
                    imageImportError = "Could not import the selected image."
                    selectedImageItem = nil
                    isImportingImage = false
                }
            }
        }
    }

    private func handleSourceTypeChange(_ sourceType: ImportSource) {
        if sourceType != .text {
            draft.clearPastedText()
            isShowingTextImport = false
        }

        if sourceType != .pdf {
            ImportedPDFStorage.delete(storedReference: draft.sourceFilePath)
            draft.clearPDF()
            isShowingPDFImporter = false
            pdfImportError = nil
        }

        if sourceType != .image {
            ImportedImageStorage.delete(storedReference: draft.imageFilePath)
            draft.clearImage()
            selectedImageItem = nil
            imageImportError = nil
            isImportingImage = false
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
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.primary : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

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
                .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.4))
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.primary : Color.secondary.opacity(0.24), lineWidth: isSelected ? 1.5 : 1)
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
        currentRow: 3,
        repeatCurrent: 1,
        repeatTotal: 4,
        rows: ["Cast on", "Knit", "Bind off"]
    ))

    return ProjectListView()
        .modelContainer(container)
}

import SwiftData
import SwiftUI

struct ImageReadingView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    private let viewModel = ImageReadingViewModel()

    var body: some View {
        let imageReferences = viewModel.imageReferences(for: project)
        Group {
            if !imageReferences.isEmpty {
                ZoomableImagePagesView(
                    imageReferences: imageReferences,
                    readingPosition: viewModel.restoreReadingPosition(for: project),
                    onReadingPositionChanged: { position in
                        viewModel.saveReadingPosition(position, for: project, in: modelContext)
                    }
                )
                .overlay(alignment: .bottomLeading) {
                    Label("Pinch to zoom - drag to pan", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.monospaced())
                        .foregroundStyle(LoopLineTheme.readingSecondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(LoopLineTheme.mediaHintBackground, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
                        .padding(18)
                    }
                    .accessibilityIdentifier("imageReadingMode")
            } else {
                ContentUnavailableView(
                    "Image Unavailable",
                    systemImage: "photo",
                    description: Text("The imported images could not be found.")
                )
                .foregroundStyle(LoopLineTheme.primaryText, LoopLineTheme.accent, LoopLineTheme.secondaryText)
            }
        }
    }
}

#Preview("Image Missing") {
    NavigationStack {
        ImageReadingView(project: Project(
            name: "Image Pattern",
            sourceType: .image,
            sourceFilePath: "/missing/pattern.jpg"
        ))
    }
}

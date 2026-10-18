import SwiftData
import SwiftUI

struct ImageReadingView: View {
    @Query private var settings: [AppSettings]
    @Bindable var project: Project
    private let viewModel = ImageReadingViewModel()

    private var usesLargeControls: Bool {
        settings.first?.largeControls ?? true
    }

    var body: some View {
        VStack(spacing: 0) {
            ReadingTrackingControls(project: project, usesLargeControls: usesLargeControls)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)

            if let imageReference = viewModel.imageReference(for: project) {
                ScrollView([.vertical, .horizontal]) {
                    StoredImagePreview(
                        storedReference: imageReference,
                        height: nil,
                        contentMode: .fit
                    )
                    .padding(18)
                    .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: LoopLineTheme.cornerRadius, style: .continuous))
                }
                .overlay(alignment: .bottomLeading) {
                    Label("Pinch to zoom - drag to pan", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.monospaced())
                        .foregroundStyle(LoopLineTheme.readingSecondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(LoopLineTheme.mediaHintBackground, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
                        .padding(18)
                }
            } else {
                ContentUnavailableView(
                    "Image Unavailable",
                    systemImage: "photo",
                    description: Text("The imported image could not be found.")
                )
                .foregroundStyle(LoopLineTheme.primaryText, LoopLineTheme.accent, LoopLineTheme.secondaryText)
            }
        }
        .background(LoopLineTheme.readingBackground.ignoresSafeArea())
        .navigationTitle("Reading Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(LoopLineTheme.readingBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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

import SwiftUI

struct ImageReadingView: View {
    let project: Project

    var body: some View {
        Group {
            if project.sourceType == .image, let sourceFilePath = project.sourceFilePath {
                ScrollView([.vertical, .horizontal]) {
                    StoredImagePreview(
                        storedReference: sourceFilePath,
                        height: nil,
                        contentMode: .fit
                    )
                    .padding(18)
                }
                .background(LoopLineTheme.readingBackground.ignoresSafeArea())
                .overlay(alignment: .bottomLeading) {
                    Text("Pinch to zoom - drag to pan")
                        .font(.caption.monospaced())
                        .foregroundStyle(LoopLineTheme.readingSecondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(LoopLineTheme.mediaHintBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(18)
                }
            } else {
                ContentUnavailableView(
                    "Image Unavailable",
                    systemImage: "photo",
                    description: Text("The imported image could not be found.")
                )
            }
        }
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

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
                .background(readingBackground.ignoresSafeArea())
                .overlay(alignment: .bottomLeading) {
                    Text("Pinch to zoom - drag to pan")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.58))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(readingBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var readingBackground: Color {
        Color(red: 0.06, green: 0.09, blue: 0.14)
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

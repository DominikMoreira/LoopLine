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
                    .padding()
                }
                .background(Color(.systemBackground))
            } else {
                ContentUnavailableView(
                    "Image Unavailable",
                    systemImage: "photo",
                    description: Text("The imported image could not be found.")
                )
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
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

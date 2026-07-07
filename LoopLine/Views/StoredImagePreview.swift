import SwiftUI
import UIKit

struct StoredImagePreview: View {
    let storedReference: String
    var height: CGFloat = 180

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ContentUnavailableView(
                    "Image Unavailable",
                    systemImage: "photo",
                    description: Text("The imported image could not be found.")
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var image: UIImage? {
        guard let fileURL = ImportedImageStorage.fileURL(for: storedReference),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return UIImage(data: data)
    }
}

import SwiftUI
import UIKit

struct StoredImagePreview: View {
    let storedReference: String
    var height: CGFloat? = 180
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var didFailToLoad = false

    var body: some View {
        Group {
            if let image {
                previewImage(image)
            } else if didFailToLoad {
                ContentUnavailableView(
                    "Image Unavailable",
                    systemImage: "photo",
                    description: Text("The imported image could not be found.")
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: storedReference) {
            await loadImage()
        }
    }

    @ViewBuilder
    private func previewImage(_ image: UIImage) -> some View {
        let swiftUIImage = Image(uiImage: image)
            .resizable()

        switch contentMode {
        case .fit:
            swiftUIImage.scaledToFit()
        case .fill:
            swiftUIImage.scaledToFill()
        }
    }

    @MainActor
    private func loadImage() async {
        image = nil
        didFailToLoad = false

        let loadedImage = await StoredImagePreviewLoader.image(for: storedReference)
        if let loadedImage {
            image = loadedImage
        } else {
            didFailToLoad = true
        }
    }
}

@MainActor
private enum StoredImagePreviewLoader {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(for storedReference: String) async -> UIImage? {
        let cacheKey = storedReference as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard let fileURL = ImportedImageStorage.fileURL(for: storedReference) else {
            return nil
        }

        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let data = try? Data(contentsOf: fileURL) else {
                return nil
            }

            return UIImage(data: data)
        }.value

        if let image {
            cache.setObject(image, forKey: cacheKey)
        }

        return image
    }
}

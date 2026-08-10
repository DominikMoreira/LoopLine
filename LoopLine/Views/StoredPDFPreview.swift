import PDFKit
import SwiftUI
import UIKit

struct StoredPDFPreview: View {
    let storedReference: String
    var height: CGFloat? = 190
    @State private var previewImage: UIImage?
    @State private var didFailToLoad = false

    var body: some View {
        Group {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LoopLineTheme.surface)
            } else if didFailToLoad {
                LoopLineSourcePlaceholder(sourceType: .pdf, label: "Cover Image")
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LoopLineTheme.surface)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .allowsHitTesting(false)
        .task(id: storedReference) {
            await loadPreview()
        }
    }

    @MainActor
    private func loadPreview() async {
        previewImage = nil
        didFailToLoad = false

        let image = await StoredPDFPreviewLoader.previewImage(for: storedReference)
        if let image {
            previewImage = image
        } else {
            didFailToLoad = true
        }
    }
}

@MainActor
private enum StoredPDFPreviewLoader {
    private static let cache = NSCache<NSString, UIImage>()

    static func previewImage(for storedReference: String) async -> UIImage? {
        let cacheKey = storedReference as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard let fileURL = ImportedPDFStorage.fileURL(for: storedReference) else {
            return nil
        }

        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let document = PDFDocument(url: fileURL),
                  let page = document.page(at: 0) else {
                return nil
            }

            let pageBounds = page.bounds(for: .cropBox)
            guard pageBounds.width > 0, pageBounds.height > 0 else {
                return nil
            }

            let maxPixelSize: CGFloat = 1400
            let scale = min(maxPixelSize / pageBounds.width, maxPixelSize / pageBounds.height)
            let thumbnailSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
            return page.thumbnail(of: thumbnailSize, for: .cropBox)
        }.value

        if let image {
            cache.setObject(image, forKey: cacheKey)
        }

        return image
    }
}

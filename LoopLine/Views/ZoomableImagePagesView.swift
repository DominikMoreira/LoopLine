import SwiftUI
import UIKit

struct ZoomableImagePagesView: UIViewRepresentable {
    let imageReferences: [String]
    let readingPosition: ImageReadingPosition
    let onReadingPositionChanged: (ImageReadingPosition) -> Void

    func makeUIView(context: Context) -> ImagePagesScrollView {
        ImagePagesScrollView(
            imageReferences: imageReferences,
            readingPosition: readingPosition,
            onReadingPositionChanged: onReadingPositionChanged
        )
    }

    func updateUIView(_ scrollView: ImagePagesScrollView, context: Context) {
        scrollView.update(
            imageReferences: imageReferences,
            readingPosition: readingPosition,
            onReadingPositionChanged: onReadingPositionChanged
        )
    }

    static func dismantleUIView(_ scrollView: ImagePagesScrollView, coordinator: ()) {
        scrollView.saveCurrentReadingPosition()
    }
}

final class ImagePagesScrollView: UIScrollView, UIScrollViewDelegate {
    private let contentView = UIView()
    private let pagesStack = UIStackView()
    private var imageReferences: [String] = []
    private var imageViews: [UIImageView] = []
    private var readingPosition = ImageReadingPosition(pageIndex: 0, verticalPosition: 0)
    private var onReadingPositionChanged: (ImageReadingPosition) -> Void
    private var hasRestoredReadingPosition = false

    init(
        imageReferences: [String],
        readingPosition: ImageReadingPosition,
        onReadingPositionChanged: @escaping (ImageReadingPosition) -> Void
    ) {
        self.onReadingPositionChanged = onReadingPositionChanged
        self.readingPosition = readingPosition
        super.init(frame: .zero)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        bouncesZoom = true
        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = true
        backgroundColor = .clear

        pagesStack.axis = .vertical
        pagesStack.spacing = 18
        pagesStack.alignment = .fill
        pagesStack.distribution = .fill

        contentView.translatesAutoresizingMaskIntoConstraints = false
        pagesStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.addSubview(pagesStack)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            pagesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            pagesStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            pagesStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            pagesStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        ])

        update(
            imageReferences: imageReferences,
            readingPosition: readingPosition,
            onReadingPositionChanged: onReadingPositionChanged
        )
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        restoreReadingPositionIfNeeded()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        saveCurrentReadingPosition()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            saveCurrentReadingPosition()
        }
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        saveCurrentReadingPosition()
    }

    func update(
        imageReferences: [String],
        readingPosition: ImageReadingPosition,
        onReadingPositionChanged: @escaping (ImageReadingPosition) -> Void
    ) {
        self.onReadingPositionChanged = onReadingPositionChanged

        guard self.imageReferences != imageReferences else { return }

        self.imageReferences = imageReferences
        self.readingPosition = readingPosition
        hasRestoredReadingPosition = false
        imageViews.removeAll()
        pagesStack.arrangedSubviews.forEach {
            pagesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for reference in imageReferences {
            guard let fileURL = ImportedImageStorage.fileURL(for: reference),
                  let image = UIImage(contentsOfFile: fileURL.path),
                  image.size.width > 0 else {
                continue
            }

            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .secondarySystemBackground
            imageView.isAccessibilityElement = true
            imageView.accessibilityLabel = String(localized: "Pattern page")
            imageView.translatesAutoresizingMaskIntoConstraints = false
            pagesStack.addArrangedSubview(imageView)
            imageViews.append(imageView)
            imageView.heightAnchor.constraint(
                equalTo: imageView.widthAnchor,
                multiplier: image.size.height / image.size.width
            ).isActive = true
        }

        setZoomScale(minimumZoomScale, animated: false)
        setContentOffset(.zero, animated: false)
        setNeedsLayout()
    }

    func saveCurrentReadingPosition() {
        guard let position = currentReadingPosition() else { return }
        onReadingPositionChanged(position)
    }

    private func restoreReadingPositionIfNeeded() {
        guard !hasRestoredReadingPosition,
              !imageViews.isEmpty,
              bounds.height > 0 else {
            return
        }

        hasRestoredReadingPosition = true
        let pageIndex = min(max(readingPosition.pageIndex, 0), imageViews.count - 1)
        let page = imageViews[pageIndex]
        let targetY = page.frame.minY + (page.bounds.height * readingPosition.verticalPosition)
        let maximumOffsetY = max(contentSize.height - bounds.height, 0)
        let offsetY = min(max(targetY - (bounds.height / 2), 0), maximumOffsetY)
        setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
    }

    private func currentReadingPosition() -> ImageReadingPosition? {
        guard !imageViews.isEmpty else { return nil }

        let midpoint = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: pagesStack)
        guard let pageIndex = imageViews.indices.min(by: {
            abs(imageViews[$0].frame.midY - midpoint.y) < abs(imageViews[$1].frame.midY - midpoint.y)
        }) else {
            return nil
        }

        let page = imageViews[pageIndex]
        guard page.bounds.height > 0 else { return nil }
        let verticalPosition = min(max((midpoint.y - page.frame.minY) / page.bounds.height, 0), 1)
        return ImageReadingPosition(pageIndex: pageIndex, verticalPosition: verticalPosition)
    }
}

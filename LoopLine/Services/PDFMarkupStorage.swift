import Foundation
import PDFKit
import UIKit

struct PDFMarkupStorage {
    let pdfURL: URL

    private var fileURL: URL {
        pdfURL
            .deletingPathExtension()
            .appendingPathExtension("loopline-markups.json")
    }

    func load() throws -> [PDFMarkupStroke] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([PDFMarkupStroke].self, from: data)
    }

    func save(_ strokes: [PDFMarkupStroke]) throws {
        let data = try JSONEncoder().encode(strokes)
        try data.write(to: fileURL, options: [.atomic])
    }
}

struct PDFMarkupStroke: Codable, Identifiable {
    var id = UUID()
    var pageIndex: Int
    var points: [PDFMarkupPoint]
    var color: PDFMarkupColor
    var width: Double
    var isMarker: Bool

    func contains(_ point: CGPoint, within distance: CGFloat) -> Bool {
        guard !points.isEmpty else { return false }

        let cgPoints = points.map(\.cgPoint)
        if cgPoints.contains(where: { hypot($0.x - point.x, $0.y - point.y) <= distance }) {
            return true
        }

        guard cgPoints.count > 1 else { return false }
        for index in 1..<cgPoints.count {
            if point.distance(toSegmentFrom: cgPoints[index - 1], to: cgPoints[index]) <= distance {
                return true
            }
        }

        return false
    }

    func erasing(at point: CGPoint, withRadius radius: CGFloat) -> [PDFMarkupStroke] {
        guard points.count > 1 else { return [self] }

        let eraserRadius = max(radius, 0)
        let cgPoints = points.map(\.cgPoint)
        var fragments = [[PDFMarkupPoint]]()
        var activeFragment = [PDFMarkupPoint]()
        var removedPortion = false

        for index in 1..<cgPoints.count {
            let start = cgPoints[index - 1]
            let end = cgPoints[index]
            let visibleSegments = visibleSegments(from: start, to: end, outside: point, radius: eraserRadius)

            if visibleSegments.count != 1 || visibleSegments.first?.lowerBound != 0 || visibleSegments.first?.upperBound != 1 {
                removedPortion = true
            }

            for segment in visibleSegments {
                let segmentStart = start.interpolated(toward: end, at: segment.lowerBound)
                let segmentEnd = start.interpolated(toward: end, at: segment.upperBound)

                if let lastPoint = activeFragment.last?.cgPoint, lastPoint.isApproximatelyEqual(to: segmentStart) {
                    activeFragment.append(PDFMarkupPoint(segmentEnd))
                } else {
                    if activeFragment.count > 1 {
                        fragments.append(activeFragment)
                    }
                    activeFragment = [PDFMarkupPoint(segmentStart), PDFMarkupPoint(segmentEnd)]
                }
            }

            if visibleSegments.isEmpty, activeFragment.count > 1 {
                fragments.append(activeFragment)
                activeFragment.removeAll()
            }
        }

        if activeFragment.count > 1 {
            fragments.append(activeFragment)
        }

        guard removedPortion else { return [self] }

        return fragments.map {
            PDFMarkupStroke(
                pageIndex: pageIndex,
                points: $0,
                color: color,
                width: width,
                isMarker: isMarker
            )
        }
    }

    private func visibleSegments(
        from start: CGPoint,
        to end: CGPoint,
        outside center: CGPoint,
        radius: CGFloat
    ) -> [ClosedRange<CGFloat>] {
        let deltaX = end.x - start.x
        let deltaY = end.y - start.y
        let lengthSquared = deltaX * deltaX + deltaY * deltaY
        guard lengthSquared > 0 else {
            return hypot(start.x - center.x, start.y - center.y) > radius ? [0...1] : []
        }

        let offsetX = start.x - center.x
        let offsetY = start.y - center.y
        let projection = offsetX * deltaX + offsetY * deltaY
        let discriminant = projection * projection - lengthSquared * (offsetX * offsetX + offsetY * offsetY - radius * radius)

        guard discriminant > 0 else {
            return [0...1]
        }

        let root = sqrt(discriminant)
        let entry = max(0, min(1, (-projection - root) / lengthSquared))
        let exit = max(0, min(1, (-projection + root) / lengthSquared))

        guard entry < exit else {
            return [0...1]
        }

        var segments = [ClosedRange<CGFloat>]()
        if entry > 0 {
            segments.append(0...entry)
        }
        if exit < 1 {
            segments.append(exit...1)
        }
        return segments
    }
}

struct PDFMarkupPoint: Codable {
    var x: Double
    var y: Double

    init(_ point: CGPoint) {
        x = Double(point.x)
        y = Double(point.y)
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

struct PDFMarkupColor: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        var white: CGFloat = 0

        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            self.red = Double(red)
            self.green = Double(green)
            self.blue = Double(blue)
            self.alpha = Double(alpha)
        } else if color.getWhite(&white, alpha: &alpha) {
            self.red = Double(white)
            self.green = Double(white)
            self.blue = Double(white)
            self.alpha = Double(alpha)
        } else {
            self.red = 1
            self.green = 0.8
            self.blue = 0
            self.alpha = 0.38
        }
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private extension CGPoint {
    func interpolated(toward point: CGPoint, at progress: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (point.x - x) * progress,
            y: y + (point.y - y) * progress
        )
    }

    func isApproximatelyEqual(to point: CGPoint, tolerance: CGFloat = 0.001) -> Bool {
        hypot(x - point.x, y - point.y) <= tolerance
    }

    func distance(toSegmentFrom start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        guard dx != 0 || dy != 0 else {
            return hypot(x - start.x, y - start.y)
        }

        let projection = ((x - start.x) * dx + (y - start.y) * dy) / (dx * dx + dy * dy)
        let clampedProjection = min(max(projection, 0), 1)
        let closestPoint = CGPoint(
            x: start.x + clampedProjection * dx,
            y: start.y + clampedProjection * dy
        )
        return hypot(x - closestPoint.x, y - closestPoint.y)
    }
}

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

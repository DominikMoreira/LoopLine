import Foundation
import ImageIO
import SwiftData
import UniformTypeIdentifiers

@Model
final class Project {
    var id: UUID
    var name: String
    var subtitle: String?
    var detailMeta: String?
    var sourceType: ImportSource
    var currentRow: Int
    var repeatCurrent: Int
    var repeatTotal: Int?
    var rows: [String]
    var sourceText: String?
    var sourceFilePath: String?
    var coverImagePath: String?

    @Relationship(deleteRule: .cascade, inverse: \ProjectNote.project)
    var notes: [ProjectNote]

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String? = nil,
        detailMeta: String? = nil,
        sourceType: ImportSource,
        currentRow: Int = 1,
        repeatCurrent: Int = 1,
        repeatTotal: Int? = nil,
        rows: [String] = [],
        sourceText: String? = nil,
        sourceFilePath: String? = nil,
        coverImagePath: String? = nil,
        notes: [ProjectNote] = []
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.detailMeta = detailMeta
        self.sourceType = sourceType
        self.currentRow = currentRow
        self.repeatCurrent = repeatCurrent
        self.repeatTotal = repeatTotal
        self.rows = rows
        self.sourceText = sourceText
        self.sourceFilePath = sourceFilePath
        self.coverImagePath = coverImagePath
        self.notes = notes
    }
}

enum PatternTextNormalizer {
    static func rows(from text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

enum ImportedImageStorage {
    static func directoryURL() throws -> URL {
        let applicationSupportDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupportDirectory.appendingPathComponent("ImportedImages", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func saveImageData(_ data: Data) throws -> URL {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCache: false,
            kCGImageSourceThumbnailMaxPixelSize: 2400
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let fileName = "\(UUID().uuidString).jpg"
        let destinationURL = try directoryURL().appendingPathComponent(fileName)
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let destinationOptions = [
            kCGImageDestinationLossyCompressionQuality: 0.82
        ] as CFDictionary
        CGImageDestinationAddImage(destination, image, destinationOptions)

        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }

        return destinationURL
    }

    static func fileURL(for storedReference: String) -> URL? {
        let directURL = URL(fileURLWithPath: storedReference)
        if directURL.isFileURL, FileManager.default.fileExists(atPath: directURL.path) {
            return directURL
        }

        let fileName = directURL.lastPathComponent.isEmpty ? storedReference : directURL.lastPathComponent
        guard let localURL = try? directoryURL().appendingPathComponent(fileName),
              FileManager.default.fileExists(atPath: localURL.path) else {
            return nil
        }

        return localURL
    }

    static func delete(storedReference: String?) {
        guard let storedReference,
              let fileURL = fileURL(for: storedReference) else {
            return
        }

        try? FileManager.default.removeItem(at: fileURL)
    }
}

enum ImportedPDFStorage {
    static func directoryURL() throws -> URL {
        let applicationSupportDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupportDirectory.appendingPathComponent("ImportedPDFs", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func copyIntoStorage(from sourceURL: URL) throws -> URL {
        let didStartAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileName = "\(UUID().uuidString)-\(sourceURL.lastPathComponent)"
        let destinationURL = try directoryURL().appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    static func fileURL(for storedReference: String) -> URL? {
        let directURL = URL(fileURLWithPath: storedReference)
        if directURL.isFileURL, FileManager.default.fileExists(atPath: directURL.path) {
            return directURL
        }

        let fileName = directURL.lastPathComponent.isEmpty ? storedReference : directURL.lastPathComponent
        guard let localURL = try? directoryURL().appendingPathComponent(fileName),
              FileManager.default.fileExists(atPath: localURL.path) else {
            return nil
        }

        return localURL
    }

    static func delete(storedReference: String?) {
        guard let storedReference,
              let fileURL = fileURL(for: storedReference) else {
            return
        }

        try? FileManager.default.removeItem(at: fileURL)
    }
}

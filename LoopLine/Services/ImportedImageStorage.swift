import Foundation
import ImageIO
import UniformTypeIdentifiers

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

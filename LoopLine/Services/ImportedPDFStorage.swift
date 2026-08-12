import Foundation

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

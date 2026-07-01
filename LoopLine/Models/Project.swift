import Foundation
import SwiftData

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

    @Relationship(deleteRule: .cascade)
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

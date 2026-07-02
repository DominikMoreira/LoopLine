import Foundation
import SwiftData

@Model
final class ProjectNote {
    var id: UUID
    var text: String
    var rowNumber: Int?

    init(
        id: UUID = UUID(),
        text: String,
        rowNumber: Int? = nil
    ) {
        self.id = id
        self.text = text
        self.rowNumber = rowNumber
    }
}

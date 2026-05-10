import SwiftData
import Foundation

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var category: String?
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "", content: String = "", category: String? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

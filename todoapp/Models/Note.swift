import SwiftData
import Foundation
import UIKit

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var category: String?
    var imageData: Data?
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "", content: String = "", category: String? = nil, imageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.category = category
        self.imageData = imageData
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

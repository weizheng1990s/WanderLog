import SwiftData
import Foundation

@Model
final class Tag {
    var id: UUID
    var name: String
    var entries: [Entry]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.entries = []
    }
}

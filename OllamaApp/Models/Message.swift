import Foundation
import SwiftData

@Model
class Message {
    var id: UUID
    var role: String
    var content: String
    var chat: ChatSession?
    var context: [Int]?
    
    init(id: UUID = UUID(), role: String, content: String, context: [Int]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.context = context
    }
}

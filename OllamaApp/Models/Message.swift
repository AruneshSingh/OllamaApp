import Foundation
import SwiftData

@Model
class Message {
    var id: UUID
    var role: String
    var content: String
    var chat: ChatSession?
    
    init(id: UUID = UUID(), role: String, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}

// End of file. No additional code.

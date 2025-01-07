import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var role: String
    var content: String
    var chat: ChatSession?
    private var contextData: Data?
    
    var context: [Int]? {
        get {
            guard let contextData else { return nil }
            return try? JSONDecoder().decode([Int].self, from: contextData)
        }
        set {
            if let newValue {
                contextData = try? JSONEncoder().encode(newValue)
            } else {
                contextData = nil
            }
        }
    }
    
    init(id: UUID = UUID(), role: String, content: String, context: [Int]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        if let context {
            self.contextData = try? JSONEncoder().encode(context)
        }
    }
}

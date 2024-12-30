import Foundation
import SwiftData

@Model
class ChatSession {
    var id: UUID
    var date: Date
    var lastUpdated: Date
    var title: String
    var modelName: String
    
    @Relationship(deleteRule: .cascade)
    var messages: [Message] = []
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         lastUpdated: Date = Date(),
         title: String,
         modelName: String,
         messages: [Message] = []) {
        self.id = id
        self.date = date
        self.lastUpdated = lastUpdated
        self.title = title
        self.modelName = modelName
        self.messages = messages
        // Link messages to this chat
        messages.forEach { $0.chat = self }
    }
    
    static func generateTitle(from messages: [Message]) -> String {
        if let firstMessage = messages.first(where: { $0.role == "user" }) {
            let title = firstMessage.content
                .prefix(50)
                .components(separatedBy: .newlines)[0]
            return title
        }
        return "New Chat"
    }
}

// Rest of the response structs remain the same
struct ModelsResponse: Codable {
    let models: [ModelInfo]
}

struct ModelInfo: Codable {
    let name: String
}

struct GenerateRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
}

struct GenerateResponse: Codable {
    let response: String
    let done: Bool
}

// End of file. No additional code.

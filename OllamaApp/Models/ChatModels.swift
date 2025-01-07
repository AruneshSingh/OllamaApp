import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var date: Date
    var lastUpdated: Date
    var title: String
    var modelName: String
    
    @Relationship(deleteRule: .cascade)
    var messages: [Message] = []
    
    private var contextData: Data?
    
    var currentContext: [Int]? {
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
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         lastUpdated: Date = Date(),
         title: String,
         modelName: String,
         messages: [Message] = [],
         currentContext: [Int]? = nil) {
        self.id = id
        self.date = date
        self.lastUpdated = lastUpdated
        self.title = title
        self.modelName = modelName
        self.messages = messages
        if let currentContext {
            self.contextData = try? JSONEncoder().encode(currentContext)
        }
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

@Model
class AvailableModels {
    var models: [String]
    var lastUpdated: Date
    
    init(models: [String] = [], lastUpdated: Date = Date()) {
        self.models = models
        self.lastUpdated = lastUpdated
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

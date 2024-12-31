import Foundation
import SwiftData

@Model
final class AppSettings {
    // Keep track of each settings instance with a unique ID
    @Attribute(.unique) var id: UUID
    // Store the default model selection with initial empty value
    var defaultModel: String
    // Track when settings were last updated
    var lastUpdated: Date
    
    init(id: UUID = UUID(), defaultModel: String = "", lastUpdated: Date = Date()) {
        self.id = id
        self.defaultModel = defaultModel
        self.lastUpdated = lastUpdated
    }
    
    // Helper to check if a default model is set
    var hasDefaultModel: Bool {
        !defaultModel.isEmpty
    }
}

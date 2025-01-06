import Foundation
import SwiftData

enum TaggedModel: String, CaseIterable {
    case code = "@code"
    case image = "@image"
    case chat = "@chat"
}

class DictionaryTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        [NSDictionary.self]
    }
    
    static let name = NSValueTransformerName(rawValue: "DictionaryTransformer")
    
    public static func register() {
        let transformer = DictionaryTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}

@Model
final class AppSettings {
    // Keep track of each settings instance with a unique ID
    @Attribute(.unique) var id: UUID
    // Store the default model selection with initial empty value
    var defaultModel: String
    // Track when settings were last updated
    var lastUpdated: Date
    
    // Store tag mappings as Data
    private var tagModelMappingsData: Data?
    
    var tagModelMappings: [String: String] {
        get {
            guard let data = tagModelMappingsData,
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            tagModelMappingsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(id: UUID = UUID(), defaultModel: String = "", lastUpdated: Date = Date()) {
        self.id = id
        self.defaultModel = defaultModel
        self.lastUpdated = lastUpdated
        // Initialize tag mappings with default model
        let initialMappings = Dictionary(uniqueKeysWithValues:
            TaggedModel.allCases.map { ($0.rawValue, defaultModel) }
        )
        self.tagModelMappingsData = try? JSONEncoder().encode(initialMappings)
    }
    
    // Helper to check if a default model is set
    var hasDefaultModel: Bool {
        !defaultModel.isEmpty
    }
    
    // Helper to get model for a specific tag
    func getModelForTag(_ tag: String) -> String {
        return tagModelMappings[tag] ?? defaultModel
    }
    
    // Helper to update model for a specific tag
    func setModelForTag(_ tag: String, model: String) {
        var currentMappings = tagModelMappings
        currentMappings[tag] = model
        tagModelMappings = currentMappings
        lastUpdated = Date()
    }
}

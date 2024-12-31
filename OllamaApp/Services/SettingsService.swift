// Create this file in the Services directory
// File: SettingsService.swift

import SwiftUI
import SwiftData

class SettingsService: ObservableObject {
    @Published var currentSettings: AppSettings?
    private var modelContext: ModelContext?
    
    func initialize(with context: ModelContext) {
        self.modelContext = context
        loadSettings()
    }
    
    func loadSettings() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AppSettings>(sortBy: [SortDescriptor(\AppSettings.lastUpdated, order: .reverse)])
        currentSettings = try? context.fetch(descriptor).first
    }
    
    func updateDefaultModel(_ model: String) throws {
        guard let context = modelContext else { return }
        
        if let settings = currentSettings {
            settings.defaultModel = model
            settings.lastUpdated = Date()
        } else {
            let newSettings = AppSettings(defaultModel: model)
            context.insert(newSettings)
            currentSettings = newSettings
        }
        
        try context.save()
    }
}

// End of file

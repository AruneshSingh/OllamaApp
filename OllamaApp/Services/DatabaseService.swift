// Create this file in the Services directory
// File: DatabaseService.swift

import SwiftUI
import SwiftData

class DatabaseService {
    func setupModelContainer() throws -> ModelContainer {
        let schema = Schema([
            ChatSession.self,
            Message.self,
            AppSettings.self
        ])
        
        let storeURL = try getStoreURL()
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: modelConfiguration
        )
    }
    
    private func getStoreURL() throws -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let storeURL = baseURL
            .appendingPathComponent("OllamaApp", isDirectory: true)
            .appendingPathComponent("OllamaDB.store")
        
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        return storeURL
    }
}

// End of file

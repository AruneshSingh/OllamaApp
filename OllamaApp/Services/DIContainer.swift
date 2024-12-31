// Create this file in the Services directory
// File: DIContainer.swift

import SwiftUI
import SwiftData

class DIContainer: ObservableObject {
    static let shared = DIContainer()
    
    let databaseService: DatabaseService
    let settingsService: SettingsService
    let accessibilityService: AccessibilityService
    
    private init() {
        self.databaseService = DatabaseService()
        self.settingsService = SettingsService()
        self.accessibilityService = AccessibilityService()
    }
}

// End of file

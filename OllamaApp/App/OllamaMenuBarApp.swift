import SwiftUI
import SwiftData
import Accessibility

@main
struct OllamaMenuBarApp: App {
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var windowManager: WindowStateManager
    let container: ModelContainer
    
    init() {
        // Create the schema
        let schema = Schema([
            ChatSession.self,
            Message.self,
            AppSettings.self
        ])
        
        // Get the base support directory
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        
        // Create a specific URL for our store
        let storeURL = baseURL.appendingPathComponent("OllamaApp", isDirectory: true)
            .appendingPathComponent("OllamaDB.store")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        // Configure with persistence options
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true
        )
        
        do {
            // Try to delete existing store if there's an issue
            // Removed this block of code as it was removed in the new code
            // if let storeURL = storeURL, FileManager.default.fileExists(atPath: storeURL.path()) {
            //     try FileManager.default.removeItem(at: storeURL)
            // }
            
            // Use modelConfiguration instead of configurations array
            container = try ModelContainer(
                for: schema,
                configurations: modelConfiguration
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        let chat = ChatViewModel(container: container)
        _chatViewModel = StateObject(wrappedValue: chat)
        let stateManager = WindowStateManager(chatViewModel: chat)
        _windowManager = StateObject(wrappedValue: stateManager)
        
        // Setup WindowManager with dependencies
        WindowManager.shared.setup(chatViewModel: chat, windowStateManager: stateManager)
        
        // Print to verify initialization
        print("App initialized with WindowManager setup")
        
        // Add permission request
        requestAccessibilityPermissions()
    }
    
    // Add new method for permissions
    private func requestAccessibilityPermissions() {
        // Request permissions with UI prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("Accessibility permissions status: \(trusted)")
        
        // If permissions granted, reload hotkey
        if trusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                WindowManager.shared.reloadHotKey()
            }
        }
    }
    
    var body: some Scene {
        MenuBarExtra("Ollama", systemImage: "brain") {
            ContentView(windowManager: windowManager, chatViewModel: chatViewModel)
                .modelContainer(container)
                .onAppear {
                    if let mostRecentChat = chatViewModel.chatHistory.first {
                        chatViewModel.loadSession(mostRecentChat)
                    }
                }
        }
        .modelContainer(container)
        .menuBarExtraStyle(.window)
    }
}

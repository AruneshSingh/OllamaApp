import SwiftUI
import SwiftData

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
        _windowManager = StateObject(wrappedValue: WindowStateManager(chatViewModel: chat))
    }
    
    var body: some Scene {
        MenuBarExtra("Ollama", systemImage: "brain") {
            ContentView(windowManager: windowManager, chatViewModel: chatViewModel)
                .modelContainer(container)
                .onAppear {
                    // Load most recent chat when popup opens
                    if let mostRecentChat = chatViewModel.chatHistory.first {
                        chatViewModel.loadSession(mostRecentChat)
                    }
                }
        }
        .modelContainer(container)
        .menuBarExtraStyle(.window)
    }
}

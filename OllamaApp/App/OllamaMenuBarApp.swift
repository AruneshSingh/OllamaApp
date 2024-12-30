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
        
        // Basic configuration
        let modelConfiguration = ModelConfiguration(schema: schema)
        
        do {
            container = try ModelContainer(for: schema, configurations: modelConfiguration)
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
        }
        .modelContainer(container)
        .menuBarExtraStyle(.window)
    }
}

// End of file. No additional code.

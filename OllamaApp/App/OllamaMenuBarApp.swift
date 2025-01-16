import SwiftUI
import SwiftData

@main
struct OllamaMenuBarApp: App {
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var diContainer: DIContainer
    private let initializedContainer: ModelContainer
    
    init() {
        DictionaryTransformer.register()
        
        do {
            initializedContainer = try DIContainer.shared.databaseService.setupModelContainer()
        } catch {
            fatalError("Failed to initialize container: \(error)")
        }
        
        let container = DIContainer.shared
        container.settingsService.initialize(with: initializedContainer.mainContext)
        _diContainer = StateObject(wrappedValue: container)
        
        let chat = ChatViewModel(container: initializedContainer)
        _chatViewModel = StateObject(wrappedValue: chat)
        
        WindowManager.shared.setup(chatViewModel: chat)
    }
    
    var body: some Scene {
        MenuBarExtra("Ollama", systemImage: "brain") {
            Button("Open App") {
                WindowManager.shared.showMainWindow()
            }
            
            Button("Open Pinned Window") {
                WindowManager.shared.showPinnedWindow()
            }
            .keyboardShortcut(.space, modifiers: [.control])
            
            Button("Open Quick Input") {
                WindowManager.shared.showQuickInputWindow()
            }
            .keyboardShortcut(.space, modifiers: [.control, .shift])
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .menuBarExtraStyle(.menu)
    }
}

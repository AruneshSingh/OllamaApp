import SwiftUI
import SwiftData
import Accessibility

@main
struct OllamaMenuBarApp: App {
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var windowManager: WindowStateManager
    @StateObject private var diContainer: DIContainer
    private let initializedContainer: ModelContainer
    
    init() {
        // Initialize container first
        do {
            initializedContainer = try DIContainer.shared.databaseService.setupModelContainer()
        } catch {
            fatalError("Failed to initialize container: \(error)")
        }
        
        // Initialize DIContainer
        let container = DIContainer.shared
        container.settingsService.initialize(with: initializedContainer.mainContext)
        _diContainer = StateObject(wrappedValue: container)
        
        // Initialize ChatViewModel
        let chat = ChatViewModel(container: initializedContainer)
        _chatViewModel = StateObject(wrappedValue: chat)
        
        // Initialize WindowManager
        let manager = WindowStateManager(chatViewModel: chat)
        _windowManager = StateObject(wrappedValue: manager)
        
        // Setup WindowManager
        WindowManager.shared.setup(chatViewModel: chat, windowStateManager: manager)
        
        // Setup accessibility
        container.accessibilityService.setupPermissions { trusted in
            if trusted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    WindowManager.shared.reloadHotKey()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    // MARK: - Private Methods
    
    // MARK: - Private Methods
    
    var body: some Scene {
        MenuBarExtra("Ollama", systemImage: "brain") {
            Group {
                PopupContentView(windowManager: windowManager, chatViewModel: chatViewModel)
                    .modelContainer(initializedContainer)
                    .onAppear {
                        if let mostRecentChat = chatViewModel.chatHistory.first {
                            chatViewModel.loadSession(mostRecentChat)
                        }
                    }
            }
            .modifier(ModelContainerModifier(container: initializedContainer))
        }
        .menuBarExtraStyle(.window)
    }
}

struct ModelContainerModifier: ViewModifier {
    let container: ModelContainer?
    
    func body(content: Content) -> some View {
        if let container = container {
            content.modelContainer(container)
        } else {
            content
        }
    }
}

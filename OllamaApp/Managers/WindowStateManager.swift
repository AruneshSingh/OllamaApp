import SwiftUI
import AppKit

@MainActor
class WindowStateManager: ObservableObject {
    @Published var isPinned: Bool = false
    @Published var showHistory: Bool = false
    
    unowned let chatViewModel: ChatViewModel
    private var detachedWindow: NSWindow?
    
    init(chatViewModel: ChatViewModel) {
        self.chatViewModel = chatViewModel
    }
    
    func togglePin() {
        isPinned.toggle()
        
        if isPinned {
            createDetachedWindow()
            if let popupWindow = NSApp.windows.first(where: { $0.title.isEmpty }) {
                popupWindow.close()
            }
        } else {
            closeDetachedWindow()
        }
    }
    
    private func createDetachedWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Ollama Chat"
        window.center()
        window.setFrameAutosaveName("OllamaWindow")
        window.collectionBehavior = [.canJoinAllSpaces]
        window.level = .floating
        window.isReleasedWhenClosed = false
        
        let contentView = ContentView(windowManager: self, chatViewModel: chatViewModel)
        window.contentView = NSHostingView(rootView: contentView)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.detachedWindow = window
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }
    
    private func closeDetachedWindow() {
        detachedWindow?.close()
        detachedWindow = nil
    }
    
    @objc private func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == detachedWindow {
            isPinned = false
            detachedWindow = nil
        }
    }
}

import AppKit
import SwiftUI
import HotKey

class QuickInputNSWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

class QuickInputPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published private(set) var isHotkeyEnabled = false
    @Published var isPinned: Bool = false
    @Published var showHistory: Bool = false
    @Published var quickInputText: String = ""
    
    private var hotKey: HotKey?
    private var quickInputHotKey: HotKey?
    private var pinnedWindow: NSWindow?
    private var quickInputWindow: NSWindow?
    private weak var chatViewModel: ChatViewModel?
    
    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            Task { @MainActor in
                self?.setupHotKey()
                self?.setupQuickInputHotKey()
            }
        }
    }
    
    // Updated setup method to remove windowStateManager
    func setup(chatViewModel: ChatViewModel) {
        self.chatViewModel = chatViewModel
    }
    
    private func setupHotKey() {
        // Remove existing hotkey if any
        hotKey = nil
        
        // Create KeyCombo and HotKey without force unwrap
        let keyCombo = KeyCombo(key: .space, modifiers: [.control])
        hotKey = HotKey(keyCombo: keyCombo)
        
        hotKey?.keyDownHandler = { [weak self] in
            print("HotKey triggered! \(Date())")
            Task { @MainActor in
                if let window = self?.pinnedWindow, window.isVisible {
                    self?.closePinnedWindow()
                } else {
                    self?.showPinnedWindow()
                }
            }
        }
        
        isHotkeyEnabled = hotKey != nil
    }
    
    private func setupQuickInputHotKey() {
        quickInputHotKey = nil
        
        let keyCombo = KeyCombo(key: .space, modifiers: [.control, .shift])
        quickInputHotKey = HotKey(keyCombo: keyCombo)
        
        quickInputHotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                // Toggle quick input window
                if let window = self?.quickInputWindow, window.isVisible {
                    self?.closeQuickInputWindow()
                } else {
                    self?.showQuickInputWindow()
                }
            }
        }
    }
    
    func reloadHotKey() {
        Task { @MainActor [self] in
            setupHotKey()
        }
    }
    
    
    func showPinnedWindow() {
        guard let chatViewModel = chatViewModel else { return }
        
        // Load most recent chat if no chat is currently loaded
        if chatViewModel.messages.isEmpty, let mostRecentChat = chatViewModel.chatHistory.first {
            chatViewModel.loadSession(mostRecentChat)
        }
        
        if pinnedWindow == nil {
            let contentView = PinnedContentView(chatViewModel: chatViewModel)
                .modelContainer(chatViewModel.container)
            
            let hostingView = NSHostingView(rootView: contentView)
            pinnedWindow = WindowConfiguration.createWindow(
                title: "Ollama",
                contentView: hostingView,
                isPinned: true
            )
            
            if let window = pinnedWindow {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces]
                window.setFrameAutosaveName("OllamaPinnedWindow")
                window.styleMask.insert(.resizable)
            }
            
            isPinned = true
        }
        
        pinnedWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showQuickInputWindow() {
        
        let rectWidth: CGFloat = 800
        let rectHeight: CGFloat = 80
        
        let rectSize = NSRect(x: 0, y: 0, width: rectWidth, height: rectHeight)
        
        guard let chatViewModel = chatViewModel else { return }
        
        let contentView = QuickInputView(chatViewModel: chatViewModel)
            .modelContainer(chatViewModel.container)
        
        let hostingView = NSHostingView(rootView: contentView)
        let panel = QuickInputPanel(
            contentRect: rectSize,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        quickInputWindow = panel
        
        if let window = quickInputWindow {
            // Configure the window
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .floating
            window.isMovableByWindowBackground = true
            window.hasShadow = false
            
            // Set up the hosting view first
            hostingView.frame = rectSize
            
            // Set up the window's content view
            window.contentView = hostingView
            
            // Center the window
            if let screen = NSScreen.main {
                let screenFrame = screen.frame
                let x = (screenFrame.width - rectWidth) / 2
                let y = (screenFrame.height - rectHeight) / 2
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func closePinnedWindow() {
        pinnedWindow?.close()
        pinnedWindow = nil
        isPinned = false
    }
    
    func closeQuickInputWindow(clearText: Bool = false) {
        if clearText {
            quickInputText = ""
        }
        quickInputWindow?.close()
        quickInputWindow = nil
    }
    
    func showMainWindow() {
        guard let chatViewModel = chatViewModel else { return }
        
        let contentView = PinnedContentView(chatViewModel: chatViewModel)
            .modelContainer(chatViewModel.container)
        
        let hostingView = NSHostingView(rootView: contentView)
        let window = WindowConfiguration.createWindow(
            title: "Ollama",
            contentView: hostingView,
            isPinned: false
        )
        
        window.setFrameAutosaveName("OllamaMainWindow")
        WindowConfiguration.showWindow(window)
    }
}

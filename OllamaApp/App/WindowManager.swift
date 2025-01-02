import AppKit
import SwiftUI
import HotKey

@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var hotKey: HotKey?
    private var quickInputHotKey: HotKey?
    private var pinnedWindow: NSWindow?
    private var popupWindow: NSWindow?
    private var quickInputWindow: NSWindow?
    private weak var chatViewModel: ChatViewModel?
    private weak var windowStateManager: WindowStateManager?
    
    @Published private(set) var isHotkeyEnabled = false
    
    init() {
        // Initialize the global hotkey
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            Task { @MainActor in
                self?.setupHotKey()
                self?.setupQuickInputHotKey()
            }
        }
    }
    
    // Setup dependencies
    func setup(chatViewModel: ChatViewModel, windowStateManager: WindowStateManager) {
        self.chatViewModel = chatViewModel
        self.windowStateManager = windowStateManager
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
    
    private func createPinnedWindowIfNeeded() {
        guard let chatViewModel = chatViewModel,
              let windowStateManager = windowStateManager else {
            print("Dependencies not set up")
            return
        }
        
        // Update isPinned state on main thread
        windowStateManager.isPinned = true
        
        if pinnedWindow == nil {
            windowStateManager.isPinned = true
            
            let contentView = PinnedContentView(windowManager: windowStateManager, chatViewModel: chatViewModel)
                .modelContainer(chatViewModel.container)
            
            let hostingView = NSHostingView(rootView: contentView)
            pinnedWindow = WindowConfiguration.createWindow(
                title: "Ollama Chat",
                contentView: hostingView,
                isPinned: true
            )
            
            if let window = pinnedWindow {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                window.setFrameAutosaveName("OllamaWindow")
            }
        } else {
            windowStateManager.isPinned = true
        }
    }
    
    func showPinnedWindow() {
        createPinnedWindowIfNeeded()
        
        if let window = pinnedWindow {
            WindowConfiguration.showWindow(window)
        }
    }
    
    func showPopupWindow() {
        guard let chatViewModel = chatViewModel,
              let windowStateManager = windowStateManager else { return }
        
        let contentView = PopupContentView(windowManager: windowStateManager, chatViewModel: chatViewModel)
            .modelContainer(chatViewModel.container)
        
        let hostingView = NSHostingView(rootView: contentView)
        popupWindow = WindowConfiguration.createWindow(
            title: "Ollama",
            contentView: hostingView,
            isPinned: false
        )
        
        if let window = popupWindow {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            WindowConfiguration.showWindow(window)
        }
    }
    
    func showQuickInputWindow() {
        guard let chatViewModel = chatViewModel,
              let windowStateManager = windowStateManager else { return }
        
        let contentView = QuickInputView(windowManager: windowStateManager, chatViewModel: chatViewModel)
            .modelContainer(chatViewModel.container)
        
        let hostingView = NSHostingView(rootView: contentView)
        quickInputWindow = WindowConfiguration.createWindow(
            title: "Quick Input",
            contentView: hostingView,
            isPinned: false
        )
        
        if let window = quickInputWindow {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces]
            window.styleMask = [.titled, .closable]
            
            // Center the window on screen
            if let screen = NSScreen.main {
                let windowSize = NSSize(width: 500, height: 60)
                let screenFrame = screen.frame
                let x = (screenFrame.width - windowSize.width) / 2
                let y = (screenFrame.height - windowSize.height) / 2
                window.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
            }
            
            WindowConfiguration.showWindow(window)
        }
    }
    
    func closePinnedWindow() {
        pinnedWindow?.close()
        pinnedWindow = nil
        windowStateManager?.isPinned = false
    }
    
    func closePopupWindow() {
        popupWindow?.close()
        popupWindow = nil
    }
    
    func closeQuickInputWindow() {
        quickInputWindow?.close()
        quickInputWindow = nil
    }
}

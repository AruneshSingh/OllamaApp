import AppKit
import SwiftUI
import HotKey

@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var hotKey: HotKey?
    private var pinnedWindow: NSWindow?
    private var popupWindow: NSWindow?
    private weak var chatViewModel: ChatViewModel?
    private weak var windowStateManager: WindowStateManager?
    
    @Published private(set) var isHotkeyEnabled = false
    
    init() {
        // Initialize the global hotkey
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            Task { @MainActor in
                self?.setupHotKey()
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
    
    func closePinnedWindow() {
        pinnedWindow?.close()
        pinnedWindow = nil
        windowStateManager?.isPinned = false
    }
    
    func closePopupWindow() {
        popupWindow?.close()
        popupWindow = nil
    }
}

import AppKit
import SwiftUI
import HotKey

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var hotKey: HotKey?
    private var mainWindow: NSWindow?
    private weak var chatViewModel: ChatViewModel?
    private weak var windowStateManager: WindowStateManager?
    
    @Published private(set) var isHotkeyEnabled = false
    
    init() {
        // Initialize the global hotkey
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.setupHotKey()
        }
    }
    
    // Setup dependencies
    func setup(chatViewModel: ChatViewModel, windowStateManager: WindowStateManager) {
        self.chatViewModel = chatViewModel
        self.windowStateManager = windowStateManager
        
        // Re-setup hotkey to ensure it's working
        // setupHotKey()
    }
    
    private func setupHotKey() {
        // Remove existing hotkey if any
        hotKey = nil
        
        // Create KeyCombo and HotKey without force unwrap
        let keyCombo = KeyCombo(key: .space, modifiers: [.control])
        hotKey = HotKey(keyCombo: keyCombo)
        
        // Add print statement for debugging
        print("HotKey setup complete: Ctrl + Space")
        
        hotKey?.keyDownHandler = { [weak self] in
            print("HotKey triggered! \(Date())")
            self?.showWindow()
        }
        
        // Check if hotkey was created successfully
        isHotkeyEnabled = hotKey != nil
        print("HotKey setup complete: Ctrl + Space. Enabled: \(isHotkeyEnabled)")
    }
    
    func reloadHotKey() {
        DispatchQueue.main.async { [weak self] in
            self?.setupHotKey()
        }
    }
    
    private func configureWindowAppearance(_ window: NSWindow) {
        // Set window transparency
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        
        // Set window appearance
        window.appearance = NSAppearance(named: .vibrantDark)
        
        // Configure window visual effect
        if let contentView = window.contentView {
            let visualEffectView = NSVisualEffectView()
            visualEffectView.frame = contentView.bounds
            visualEffectView.autoresizingMask = [.width, .height]
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.material = .hudWindow
            visualEffectView.state = .active
            
            // Insert the visual effect view behind all content
            contentView.superview?.subviews.insert(visualEffectView, at: 0)
        }
    }
    
    private func createWindowIfNeeded() {
        guard let chatViewModel = chatViewModel,
              let windowStateManager = windowStateManager else {
            print("Dependencies not set up")
            return
        }
        
        if mainWindow == nil {
            print("Creating new window")
            // Create the window
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Ollama"
            window.center()
            
            // Configure window appearance before setting content
            configureWindowAppearance(window)
            
            // Create the SwiftUI view that provides the window contents
            let contentView = ContentView(windowManager: windowStateManager, chatViewModel: chatViewModel)
                .modelContainer(chatViewModel.container) // Add model container
            
            // Create the hosting view
            let hostingView = NSHostingView(rootView: contentView)
            window.contentView = hostingView
            
            // Set minimum size
            window.minSize = NSSize(width: 300, height: 400)
            
            // Close button should only close the window, not terminate the app
            window.isReleasedWhenClosed = false
            
            // Set window to always stay on top
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            mainWindow = window
        }
    }
    
    func showWindow() {
        DispatchQueue.main.async { [weak self] in
            print("Showing window")
            self?.createWindowIfNeeded()
            
            if let window = self?.mainWindow {
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                }
                
                // Always set floating level when showing window
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                
                // Ensure window is visible and active
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            }
        }
    }
    
    func configureWindow(_ isPinned: Bool) {
        if let window = mainWindow {
            // Always keep it floating regardless of pin state
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
    }
}

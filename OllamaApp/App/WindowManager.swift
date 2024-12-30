import AppKit
import SwiftUI

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    func configureWindow(_ isPinned: Bool) {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                // Set window level
                window.level = isPinned ? .floating : .normal
                
                // Configure window properties
                window.styleMask = [
                    .titled,
                    .closable,
                    .miniaturizable,
                    .resizable
                ]
                
                // Set window behavior
                if isPinned {
                    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                } else {
                    window.collectionBehavior = []
                }
                
                // Set minimum window size
                window.minSize = NSSize(width: 300, height: 400)
                
                // Make window visible and bring to front
                window.orderFront(nil)
                if isPinned {
                    window.makeKey()
                }
            }
        }
    }
}

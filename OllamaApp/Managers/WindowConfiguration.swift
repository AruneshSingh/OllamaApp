// WindowConfiguration.swift
// Create this file in the Managers directory

import AppKit
import SwiftUI

struct WindowConfiguration {
    static func createWindow(
        title: String,
        contentView: NSView,
        size: NSSize = NSSize(width: 400, height: 600),
        isPinned: Bool = false
    ) -> NSWindow {
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Basic window setup
        window.title = title
        window.center()
        window.minSize = NSSize(width: 300, height: 400)
        window.isReleasedWhenClosed = false
        
        // Window appearance
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.appearance = NSAppearance(named: .vibrantDark)
        
        // Configure visual effect
        if let windowContentView = window.contentView {
            let visualEffectView = NSVisualEffectView()
            visualEffectView.frame = windowContentView.bounds
            visualEffectView.autoresizingMask = [.width, .height]
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.material = .hudWindow
            visualEffectView.state = .active
            windowContentView.superview?.subviews.insert(visualEffectView, at: 0)
        }
        
        // Set window behavior
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set content view
        window.contentView = contentView
        
        // Additional settings for pinned window
        if isPinned {
            window.setFrameAutosaveName("OllamaWindow")
        }
        
        return window
    }
    
    static func showWindow(_ window: NSWindow) {
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}

// End of file

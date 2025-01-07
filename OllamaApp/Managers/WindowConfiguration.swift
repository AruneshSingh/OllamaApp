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
        // Create the window with borderless style for pinned view
        let styleMask: NSWindow.StyleMask = isPinned ? 
            [.borderless] : [.titled, .closable, .miniaturizable, .resizable]
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        // Basic window setup
        window.title = title
        window.center()
        
        // Set size constraints based on window type
        if isPinned {
            window.minSize = NSSize(width: 300, height: 100)
            window.maxSize = NSSize(width: 500, height: 800)
        } else {
            window.minSize = NSSize(width: 300, height: 500)
            window.maxSize = NSSize(width: 800, height: 1000)
        }
        
        window.isReleasedWhenClosed = false
        
        // Window appearance
        window.backgroundColor = .clear // Make the window completely transparent
        window.isOpaque = false
        window.hasShadow = false // Remove window shadow for pinned view
        
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

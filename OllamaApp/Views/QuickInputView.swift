import SwiftUI
import AppKit

struct QuickInputView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @FocusState private var isFocused: Bool
    @State private var windowDelegate: QuickInputWindowDelegate? = nil
    
    private func highlightedText() -> some View {
        let text = Text(windowManager.quickInputText.isEmpty ? "Ask anything... (use @code, @image, or @chat)" : "")
            .foregroundColor(.gray)
        
        if windowManager.quickInputText.isEmpty {
            return AnyView(text)
        }
        
        var finalText = Text("")
        var currentIndex = windowManager.quickInputText.startIndex
        
        // Split text and apply styling to tags
        while currentIndex < windowManager.quickInputText.endIndex {
            var foundTag = false
            
            for tag in TaggedModel.allCases {
                if windowManager.quickInputText[currentIndex...].hasPrefix(tag.rawValue) {
                    let tagEnd = windowManager.quickInputText.index(currentIndex, offsetBy: tag.rawValue.count)
                    let beforeTag = finalText
                    
                    finalText = beforeTag + Text(tag.rawValue)
                        .foregroundColor(.blue)
                    
                    currentIndex = tagEnd
                    foundTag = true
                    break
                }
            }
            
            if !foundTag {
                finalText = finalText + Text(String(windowManager.quickInputText[currentIndex]))
                currentIndex = windowManager.quickInputText.index(after: currentIndex)
            }
        }
        
        return AnyView(finalText)
    }
    
    var body: some View {
        HStack {
            // Create a ZStack with TextField at the bottom and styled text overlay
            ZStack(alignment: .leading) {
                TextField("", text: $windowManager.quickInputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, design: .monospaced))
                    .focused($isFocused)
                    .foregroundColor(.clear) // Make text invisible but keep cursor
                    .scrollDisabled(true)
                    .frame(height: 40)
                    .task {
                        // Focus immediately when the view appears
                        isFocused = true
                    }
                    .onSubmit {
                        if !windowManager.quickInputText.isEmpty {
                            let messageText = windowManager.quickInputText
                            WindowManager.shared.closeQuickInputWindow(clearText: true)
                            chatViewModel.startNewChat()
                            chatViewModel.sendMessage(content: messageText)
                            WindowManager.shared.showPinnedWindow()
                        }
                    }
                    .onChange(of: windowManager.quickInputText) { _, newValue in
                        if newValue.contains("\n") {
                            windowManager.quickInputText = newValue.replacingOccurrences(of: "\n", with: "")
                            if !windowManager.quickInputText.isEmpty {
                                let messageText = windowManager.quickInputText
                                WindowManager.shared.closeQuickInputWindow(clearText: true)
                                chatViewModel.startNewChat()
                                chatViewModel.sendMessage(content: messageText)
                                WindowManager.shared.showPinnedWindow()
                            }
                        }
                    }
                    .onAppear {
                        isFocused = true
                    }
                
                highlightedText()
                    .font(.system(size: 16, design: .monospaced))
                    .allowsHitTesting(false)
            }
            
            Image(systemName: "return")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .modifier(GlowingBorder())
        .onAppear {
            isFocused = true
            // Set up window delegate
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    windowDelegate = QuickInputWindowDelegate()
                    window.delegate = windowDelegate
                }
            }
        }
        .onDisappear {
            // Clean up window delegate
            if let window = NSApp.windows.first(where: { $0.delegate === windowDelegate }) {
                window.delegate = nil
                windowDelegate = nil
            }
        }
    }
}

struct GlowingBorder: ViewModifier {
    @State private var phase: CGFloat = 0
    
    let colors = [Color.blue, Color.purple, Color.pink, Color.orange, Color.blue]
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    Color.black.opacity(0.4)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        AngularGradient(
                            colors: colors,
                            center: .center,
                            angle: .degrees(phase)
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 0)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
    }
}

class QuickInputWindowDelegate: NSObject, NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        WindowManager.shared.closeQuickInputWindow()
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

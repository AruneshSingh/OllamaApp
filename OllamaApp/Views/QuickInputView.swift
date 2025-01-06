import SwiftUI

struct QuickInputView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    private func highlightedText() -> some View {
        let text = Text(inputText.isEmpty ? "Ask anything... (use @code, @image, or @chat)" : "")
            .foregroundColor(.gray)
        
        if inputText.isEmpty {
            return AnyView(text)
        }
        
        var finalText = Text("")
        var currentIndex = inputText.startIndex
        
        // Split text and apply styling to tags
        while currentIndex < inputText.endIndex {
            var foundTag = false
            
            for tag in TaggedModel.allCases {
                if inputText[currentIndex...].hasPrefix(tag.rawValue) {
                    let tagEnd = inputText.index(currentIndex, offsetBy: tag.rawValue.count)
                    let beforeTag = finalText
                    
                    finalText = beforeTag + Text(tag.rawValue)
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    
                    currentIndex = tagEnd
                    foundTag = true
                    break
                }
            }
            
            if !foundTag {
                finalText = finalText + Text(String(inputText[currentIndex]))
                currentIndex = inputText.index(after: currentIndex)
            }
        }
        
        return AnyView(finalText)
    }
    
    var body: some View {
        HStack {
            // Create a ZStack with TextField at the bottom and styled text overlay
            ZStack(alignment: .leading) {
                TextField("", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20))
                    .focused($isFocused)
                    .opacity(0.01) // Just enough to show cursor
                    .scrollDisabled(true)
                    .frame(height: 40)
                    .onSubmit {
                        if !inputText.isEmpty {
                            let messageText = inputText
                            WindowManager.shared.closeQuickInputWindow()
                            chatViewModel.startNewChat()
                            chatViewModel.sendMessage(content: messageText)
                            WindowManager.shared.showPinnedWindow()
                        }
                    }
                    .onChange(of: inputText) { _, _ in
                        if inputText.contains("\n") {
                            inputText = inputText.replacingOccurrences(of: "\n", with: "")
                            if !inputText.isEmpty {
                                let messageText = inputText
                                WindowManager.shared.closeQuickInputWindow()
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
                    .font(.system(size: 20))
                    .allowsHitTesting(false)
            }
            
            Image(systemName: "return")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

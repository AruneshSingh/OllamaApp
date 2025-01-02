// Your imports remain the same
import SwiftUI

struct QuickInputView: View {
    // Your properties remain the same
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Ask anything...", text: $inputText)
                .textFieldStyle(.plain)
                .padding()
                .focused($isFocused)
                .onSubmit {
                    if !inputText.isEmpty {
                        let messageText = inputText
                        // Close quick input window
                        WindowManager.shared.closeQuickInputWindow()
                        // Open pinned window with new chat
                        chatViewModel.startNewChat()
                        chatViewModel.sendMessage(content: messageText, model: chatViewModel.selectedModel)
                        WindowManager.shared.showPinnedWindow()
                    }
                }
                .onAppear {
                    isFocused = true
                }
        }
        .frame(width: 500, height: 60)
    }
}

// End of file

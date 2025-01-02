import SwiftUI

struct QuickInputView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("Ask anything...", text: $inputText)
            .textFieldStyle(.plain)
            .font(.system(size: 20))
            .focused($isFocused)
            .onSubmit {
                if !inputText.isEmpty {
                    let messageText = inputText
                    WindowManager.shared.closeQuickInputWindow()
                    chatViewModel.startNewChat()
                    chatViewModel.sendMessage(content: messageText, model: chatViewModel.selectedModel)
                    WindowManager.shared.showPinnedWindow()
                }
            }
            .onAppear {
                isFocused = true
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
    }
}

import SwiftUI

struct QuickInputView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            TextField("Ask anything... (use @code, @image, or @chat)", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 20))
                .focused($isFocused)
                .onSubmit {
                    if !inputText.isEmpty {
                        let messageText = inputText
                        WindowManager.shared.closeQuickInputWindow()
                        chatViewModel.startNewChat()
                        chatViewModel.sendMessage(content: messageText)
                        WindowManager.shared.showPinnedWindow()
                    }
                }
                .onAppear {
                    isFocused = true
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

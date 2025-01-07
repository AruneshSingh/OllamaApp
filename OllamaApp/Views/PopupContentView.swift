import SwiftUI

// Popup view specific for menu bar popup window
struct PopupContentView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var userInput = ""
    @Namespace private var bottomID
    
    // MARK: - Layout Constants
    private enum Layout {
        static let spacing: CGFloat = 12
        static let frameWidth: CGFloat = 500
        static let minHeight: CGFloat = 400
        static let maxHeight: CGFloat = 800
        // Removed contentHeight
        
    }
    
    private func sendMessage() {
        guard !isInputDisabled else { return }
        chatViewModel.sendMessage(content: userInput, model: chatViewModel.selectedModel)
        userInput = ""
    }
    
    var body: some View {
        VStack(spacing: Layout.spacing) {
            headerView
            chatContent
            inputArea
        }
        .padding()
        .frame(width: Layout.frameWidth)
        .frame(minHeight: Layout.minHeight, maxHeight: Layout.maxHeight)
    }
    
    // MARK: - Private Views
    private var headerView: some View {
        HStack {
            Text("Ollama")
                .font(.headline)
            
            Spacer()
            
            modelPicker
            
            pinButton
        }
    }
    
    private var modelPicker: some View {
        Picker("Model", selection: .init(
            get: { chatViewModel.selectedModel },
            set: { chatViewModel.selectedModel = $0 }
        )) {
            ForEach(chatViewModel.availableModels, id: \.self) { model in
                Text(model).tag(model)
            }
        }
        .pickerStyle(.menu)
        .disabled(chatViewModel.isLoading)
        .accessibilityLabel("Select AI model")
    }
    
    private var pinButton: some View {
        Button(action: { windowManager.togglePin() }) {
            Image(systemName: "pin")
        }
        .help("Pin window")
        .accessibilityLabel("Pin window")
    }
    
    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Layout.spacing) {
                    ForEach(chatViewModel.messages) { message in
                        MessageView(message: message)
                            .id(message.id)
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.vertical)
            }
            .onChange(of: chatViewModel.messages.count, initial: false) { oldValue, newValue in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: chatViewModel.messages.last?.content) { _, _ in
                if chatViewModel.isStreaming {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }
    
    private var inputArea: some View {
        HStack {
            TextField("Ask a question...", text: $userInput)
                .textFieldStyle(.roundedBorder)
                .disabled(chatViewModel.isLoading)
                .onSubmit(sendMessage)
            
            Button("Send", action: sendMessage)
                .disabled(isInputDisabled)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Private Methods
    private var isInputDisabled: Bool {
        userInput.isEmpty ||
        chatViewModel.selectedModel.isEmpty ||
        chatViewModel.isLoading
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(bottomID, anchor: .bottom)
        }
    }
}

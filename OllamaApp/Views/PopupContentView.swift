import SwiftUI

// Popup view specific for menu bar popup window
struct PopupContentView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var userInput: String = ""
    @Namespace private var bottomID
    
    private func sendMessage() {
        guard !userInput.isEmpty &&
                !chatViewModel.selectedModel.isEmpty &&
                !chatViewModel.isLoading else { return }
        chatViewModel.sendMessage(content: userInput, model: chatViewModel.selectedModel)
        userInput = ""
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with pin button
            HStack {
                Text("Ollama")
                    .font(.headline)
                
                Spacer()
                
                Picker("Model", selection: Binding(
                    get: { chatViewModel.selectedModel },
                    set: { chatViewModel.selectedModel = $0 }
                )) {
                    ForEach(chatViewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                
                Button(action: { windowManager.togglePin() }) {
                    Image(systemName: "pin")
                }
                .help("Pin window")
            }
            
            // Chat content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(chatViewModel.messages) { message in
                            MessageView(message: message)
                        }
                        
                        if chatViewModel.isLoading {
                            LoadingView()
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                }
                .frame(height: 400)
                .onChange(of: chatViewModel.messages) { oldValue, newValue in
                    withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            
            // Input area
            HStack {
                TextField("Ask a question...", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(chatViewModel.isLoading)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button("Send") {
                    sendMessage()
                }
                .disabled(userInput.isEmpty ||
                         chatViewModel.selectedModel.isEmpty ||
                         chatViewModel.isLoading)
            }
            .padding(.bottom, 8)
        }
        .padding()
    }
}

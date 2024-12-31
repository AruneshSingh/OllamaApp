import SwiftUI

// Pinned window view with settings and history buttons
struct PinnedContentView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var userInput: String = ""
    @State private var showSettings = false
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
            // Header with settings and history buttons
            HStack {
                Text("Ollama Chat")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { chatViewModel.startNewChat() }) {
                    Image(systemName: "square.and.pencil")
                }
                .help("Start new chat")
                
                Picker("Model", selection: Binding(
                    get: { chatViewModel.selectedModel },
                    set: { chatViewModel.selectedModel = $0 }
                )) {
                    ForEach(chatViewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                
                Button(action: { windowManager.showHistory.toggle() }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .help("Show chat history")
                
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gear")
                }
                .help("Settings")
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
        .sheet(isPresented: $windowManager.showHistory) {
            HistoryView(
                viewModel: chatViewModel,
                showHistory: $windowManager.showHistory
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                showSettings: $showSettings,
                chatViewModel: chatViewModel
            )
        }
    }
}

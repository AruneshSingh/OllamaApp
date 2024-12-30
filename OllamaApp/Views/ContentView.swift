import SwiftUI

struct ContentView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var userInput: String = ""
    @State private var showSettings = false
    @Namespace private var bottomID
    
    var navigationTitle: String {
        if chatViewModel.isNewChat {
            return "New Chat"
        }
        if let currentId = chatViewModel.currentSessionId,
           let session = chatViewModel.chatHistory.first(where: { $0.id == currentId }) {
            return session.title
        }
        return "Chat"
    }
    
    private func sendMessage() {
        guard !userInput.isEmpty &&
                !chatViewModel.selectedModel.isEmpty &&
                !chatViewModel.isLoading else { return }
        chatViewModel.sendMessage(content: userInput, model: chatViewModel.selectedModel)
        userInput = ""
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(navigationTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                Picker("Model", selection: $chatViewModel.selectedModel) {
                    ForEach(chatViewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                
                if windowManager.isPinned {
                    Button(action: { chatViewModel.startNewChat() }) {
                        Image(systemName: "square.and.pencil")
                    }
                    .help("Start new chat")
                    
                    Button(action: { windowManager.showHistory.toggle() }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .help("Show chat history")
                    
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                    .help("Settings")
                } else {
                    Button(action: { windowManager.togglePin() }) {
                        Image(systemName: "pin")
                    }
                    .help("Pin window")
                }
            }
            
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
                .onChange(of: chatViewModel.messages) { _ in
                    withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            
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
        .frame(minWidth: 400, minHeight: 500)
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
        .onAppear {
            chatViewModel.fetchAvailableModels()
        }
        .onChange(of: windowManager.showHistory) { newValue in
            if !newValue {
                chatViewModel.objectWillChange.send()
            }
        }
    }
}

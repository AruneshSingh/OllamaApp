import SwiftUI

// Pinned window view with settings and history buttons
struct PinnedContentView: View {
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var userInput: String = ""
    @State private var showSettings = false
    @State private var isHovered = false
    @Namespace private var bottomID
    
    private func sendMessage() {
        guard !userInput.isEmpty &&
                !chatViewModel.selectedModel.isEmpty &&
                !chatViewModel.isLoading else { return }
        chatViewModel.sendMessage(content: userInput, model: chatViewModel.selectedModel)
        userInput = ""
    }
    
    private var lastTwoMessages: [Message] {
        Array(chatViewModel.messages.suffix(2))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isHovered {
                // Expanded view with full chat history
                VStack(spacing: 12) {
                    // Header with settings and history buttons
                    HStack {
                        Text("Better AI interface")
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
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(chatViewModel.messages) { message in
                                    MessageView(message: message)
                                        .transition(.opacity)
                                }
                                
                                if chatViewModel.isLoading {
                                    LoadingView()
                                }
                                
                                Color.clear
                                    .frame(height: 1)
                                    .id(bottomID)
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 400)
                        .onChange(of: chatViewModel.messages) { oldValue, newValue in
                            withAnimation {
                                proxy.scrollTo(bottomID, anchor: .bottom)
                            }
                        }
                    }
                }
                .transition(.opacity)
            } else {
                // Collapsed view with stacked cards
                VStack(spacing: 4) {
                    ForEach(lastTwoMessages) { message in
                        MessageView(message: message)
                            .scaleEffect(0.9)
                            .opacity(0.9)
                    }
                }
                .frame(maxHeight: 150)
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            // Input area always visible
            HStack {
                TextField("Ask a question...", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(chatViewModel.isLoading)
                    .onSubmit {
                        sendMessage()
                    }
                
                Picker("", selection: $chatViewModel.selectedModel) {
                    ForEach(chatViewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 30)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(userInput.isEmpty ||
                         chatViewModel.selectedModel.isEmpty ||
                         chatViewModel.isLoading)
            }
            .padding(8)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .shadow(radius: 5)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .frame(minHeight: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
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

struct ResizeHandle: View {
    @Binding var height: CGFloat
    @State private var dragLocation: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 100, height: 4)
            .padding(.bottom, -2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let delta = dragLocation - value.location.y
                        height = min(max(200, height + delta), 800)
                        dragLocation = value.location.y
                    }
                    .onEnded { _ in
                        dragLocation = 0
                    }
            )
            .onHover { inside in
                if inside {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

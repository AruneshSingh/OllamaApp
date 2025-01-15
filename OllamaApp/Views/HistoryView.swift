import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var showHistory: Bool
    @State private var sessionToRename: ChatSession?
    @State private var newTitle: String = ""
    
    // MARK: - Private Views
    
    private enum Layout {
        static let spacing: CGFloat = 4
        static let verticalPadding: CGFloat = 4
        static let frameWidth: CGFloat = 400
        static let frameHeight: CGFloat = 500
    }
    
    @ViewBuilder
    private func chatSessionRow(_ session: ChatSession) -> some View {
        Button(action: { selectSession(session) }) {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                HStack {
                    titleRow(session)
                    Spacer()
                    Menu {
                        Button(action: {
                            sessionToRename = session
                            newTitle = session.title
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: {
                            deleteSession(session)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                }
                modelInfo(session)
                SessionMetadata(session: session)
            }
            .padding(.vertical, Layout.verticalPadding)
        }
        .buttonStyle(.plain)
    }
    
    private func titleRow(_ session: ChatSession) -> some View {
        Text(session.title)
            .font(.headline)
            .lineLimit(1)
            .accessibilityLabel("Chat title: \(session.title)")
    }
    
    private func modelInfo(_ session: ChatSession) -> some View {
        Text("Model: \(session.modelName)")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .accessibilityLabel("Using model \(session.modelName)")
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Chat History")
                .toolbar { toolbarContent }
                .sheet(item: $sessionToRename) { session in
                    renameSessionView(session)
                }
        }
        .frame(width: Layout.frameWidth, height: Layout.frameHeight)
    }
    
    // Add rename session view
    private func renameSessionView(_ session: ChatSession) -> some View {
        NavigationStack {
            Form {
                TextField("Chat Title", text: $newTitle)
            }
            .navigationTitle("Rename Chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        sessionToRename = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        renameSession(session, to: newTitle)
                        sessionToRename = nil
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
        }
        .frame(width: 300, height: 150)
    }

    // MARK: - Private Views
    private var content: some View {
        Group {
            if viewModel.chatHistory.isEmpty {
                emptyStateView
            } else {
                chatHistoryList
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Chat History",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Start a new chat to begin")
        )
    }
    
    private var chatHistoryList: some View {
        List {
            ForEach(viewModel.chatHistory) { session in
                chatSessionRow(session)
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    showHistory = false
                }
            }
            
            ToolbarItem(placement: .destructiveAction) {
                clearHistoryButton
            }
        }
    }
    
    private var clearHistoryButton: some View {
        Button(action: clearHistory) {
            Text("Clear History")
        }
        .disabled(viewModel.chatHistory.isEmpty)
        .accessibilityLabel("Clear all chat history")
    }
    
    // MARK: - Private Methods
    private func selectSession(_ session: ChatSession) {
        viewModel.loadSession(session)
        showHistory = false
    }
    
    private func clearHistory() {
        withAnimation {
            viewModel.clearAllHistory()
        }
    }

    // Add these new methods
    private func deleteSession(_ session: ChatSession) {
        withAnimation {
            viewModel.deleteSession(session)
        }
    }
    
    private func renameSession(_ session: ChatSession, to newTitle: String) {
        viewModel.renameSession(session, to: newTitle)
    }
}

// MARK: - Supporting Views

private struct SessionMetadata: View {
    let session: ChatSession
    
    var body: some View {
        HStack {
            Text(session.lastUpdated, style: .relative)
            if !session.messages.isEmpty {
                Text("•")
                Text("\(session.messages.count) messages")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(makeAccessibilityLabel())
    }
    
    private func makeAccessibilityLabel() -> Text {
        let messageCount = session.messages.isEmpty ? "" : ", \(session.messages.count) messages"
        return Text(session.lastUpdated, style: .relative) + Text(messageCount)
    }
}

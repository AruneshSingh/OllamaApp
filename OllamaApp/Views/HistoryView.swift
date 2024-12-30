import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var showHistory: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.chatHistory) { session in
                    Button(action: {
                        viewModel.loadSession(session)
                        showHistory = false
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.title)
                                .font(.headline)
                                .lineLimit(1)
                            Text("Model: \(session.modelName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(session.lastUpdated, style: .relative)
                                if !session.messages.isEmpty {
                                    Text("•")
                                    Text("\(session.messages.count) messages")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Chat History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showHistory = false
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear History", role: .destructive) {
                        viewModel.clearAllHistory()
                    }
                    .disabled(viewModel.chatHistory.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

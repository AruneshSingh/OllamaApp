import SwiftUI

struct MessageView: View {
    let message: Message
    let isStreaming: Bool = false
    
    private var backgroundColor: Color {
        message.role == "user" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    private var accessibilityLabel: String {
        "\(message.role) message: \(message.content)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.role)
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            
            if message.content.isEmpty && message.role == "assistant" {
                LoadingView()
            } else {
                Text(message.content)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.linear(duration: 0.25), value: message.content)
                    .drawingGroup()
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}

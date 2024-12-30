import SwiftUI

struct MessageView: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.role)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(message.content)
                .textSelection(.enabled)
        }
        .padding(8)
        .background(message.role == "user" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

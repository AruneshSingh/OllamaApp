import SwiftUI

struct LoadingView: View {
    private let message: String
    private let scale: Double = 0.7
    private let spacing: CGFloat = 8
    
    init(message: String = "Thinking...", scale: Double = 0.7) {
        self.message = message
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            progressIndicator
            messageLabel
        }
        .frame(maxWidth: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message) in progress")
    }
    
    private var progressIndicator: some View {
        ProgressView()
            .scaleEffect(scale)
            .accessibilityHidden(true)
    }
    
    private var messageLabel: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

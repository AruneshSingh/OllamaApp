import SwiftUI

struct LoadingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.7)
            Text("Thinking...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

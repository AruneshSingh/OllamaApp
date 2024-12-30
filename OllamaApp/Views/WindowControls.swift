import SwiftUI

struct WindowControls: View {
    @Binding var isPinned: Bool
    @Binding var isCompact: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { isPinned.toggle() }) {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .foregroundColor(isPinned ? .blue : .gray)
            }
            .help("Pin window on top")
            
            Button(action: { isCompact.toggle() }) {
                Image(systemName: isCompact ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                    .foregroundColor(.gray)
            }
            .help("Toggle window size")
        }
        .buttonStyle(.plain)
    }
}

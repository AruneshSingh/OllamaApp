import SwiftUI
import AppKit

@MainActor
class WindowStateManager: ObservableObject {
    @Published var isPinned: Bool = false
    @Published var showHistory: Bool = false
    
    unowned let chatViewModel: ChatViewModel
    
    init(chatViewModel: ChatViewModel) {
        self.chatViewModel = chatViewModel
    }
    
    func togglePin() {
        isPinned.toggle()
        
        if isPinned {
            WindowManager.shared.showPinnedWindow()
            WindowManager.shared.closePopupWindow()
        } else {
            WindowManager.shared.closePinnedWindow()
        }
    }
}

// End of file

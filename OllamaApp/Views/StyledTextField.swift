import SwiftUI

// Add StyledTextField to handle tag styling
struct StyledTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.backgroundColor = .clear
        textField.drawsBackground = false
        textField.isBordered = false
        textField.font = .systemFont(ofSize: 20)
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Update text and styling
        let attributedString = NSMutableAttributedString(string: text)
        
        // Apply styling to tags
        for tag in TaggedModel.allCases {
            if let range = text.range(of: tag.rawValue) {
                let nsRange = NSRange(range, in: text)
                attributedString.addAttributes([
                    .foregroundColor: NSColor.blue,
                    .font: NSFont.boldSystemFont(ofSize: 20)
                ], range: nsRange)
            }
        }
        
        // Apply regular styling to non-tag text
        let fullRange = NSRange(location: 0, length: text.count)
        attributedString.addAttributes([
            .font: NSFont.systemFont(ofSize: 20),
            .foregroundColor: NSColor.textColor
        ], range: fullRange)
        
        nsView.attributedStringValue = attributedString
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: StyledTextField
        
        init(_ parent: StyledTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}


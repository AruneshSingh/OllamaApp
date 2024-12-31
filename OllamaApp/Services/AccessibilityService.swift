// Create this file in the Services directory
// File: AccessibilityService.swift

import SwiftUI
import Accessibility

class AccessibilityService {
    func setupPermissions(completion: @escaping (Bool) -> Void) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("Accessibility permissions status: \(trusted)")
        completion(trusted)
    }
}

// End of file

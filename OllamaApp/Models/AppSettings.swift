import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultModel: String
    
    init(defaultModel: String = "") {
        self.defaultModel = defaultModel
    }
}

// End of file. No additional code.

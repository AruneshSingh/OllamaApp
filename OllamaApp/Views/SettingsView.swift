import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showSettings: Bool
    @ObservedObject var chatViewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var diContainer = DIContainer.shared
    
    // Query for AppSettings
    // @Query(sort: [SortDescriptor(\AppSettings.lastUpdated, order: .reverse)]) private var appSettings: [AppSettings]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Default Model") {
                    if chatViewModel.availableModels.isEmpty {
                        Text("Loading available models...")
                    } else {
                        let currentSettings = diContainer.settingsService.currentSettings
                        
                        Picker("Default Model", selection: Binding(
                            get: {
                                currentSettings?.defaultModel ?? chatViewModel.selectedModel
                            },
                            set: { newValue in
                                try? diContainer.settingsService.updateDefaultModel(newValue)
                                chatViewModel.updateDefaultModel(newValue)
                            }
                        )) {
                            ForEach(chatViewModel.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        
                        // Debug info
                        if let currentDefault = currentSettings?.defaultModel {
                            Text("Stored default model: \(currentDefault)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showSettings = false
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            // If no settings exist and we have available models, create initial settings
            // If no settings exist and we have available models, create initial settings
            if diContainer.settingsService.currentSettings == nil && !chatViewModel.availableModels.isEmpty {
                try? diContainer.settingsService.updateDefaultModel(chatViewModel.selectedModel)
            }
        }
    }
}

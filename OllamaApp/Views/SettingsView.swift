import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showSettings: Bool
    @ObservedObject var chatViewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext
    
    // Query for AppSettings
    @Query(sort: [SortDescriptor(\AppSettings.lastUpdated, order: .reverse)]) private var appSettings: [AppSettings]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Default Model") {
                    if chatViewModel.availableModels.isEmpty {
                        Text("Loading available models...")
                    } else {
                        let currentSettings = appSettings.first
                        
                        Picker("Default Model", selection: Binding(
                            get: {
                                currentSettings?.defaultModel ?? chatViewModel.selectedModel
                            },
                            set: { newValue in
                                if let settings = currentSettings {
                                    settings.defaultModel = newValue
                                    settings.lastUpdated = Date()
                                } else {
                                    let newSettings = AppSettings(defaultModel: newValue)
                                    modelContext.insert(newSettings)
                                }
                                
                                try? modelContext.save()
                                print("Updated default model to: \(newValue)")
                                
                                // Update chatViewModel
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
            if appSettings.isEmpty && !chatViewModel.availableModels.isEmpty {
                let initialModel = chatViewModel.selectedModel
                let newSettings = AppSettings(defaultModel: initialModel)
                modelContext.insert(newSettings)
                try? modelContext.save()
                print("Created initial settings with model: \(initialModel)")
            }
        }
    }
}

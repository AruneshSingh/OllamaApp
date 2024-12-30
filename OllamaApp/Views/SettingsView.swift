import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showSettings: Bool
    @ObservedObject var chatViewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Default Model") {
                    Picker("Default Model", selection: defaultModelBinding) {
                        Text("None").tag("")
                        ForEach(chatViewModel.availableModels, id: \.self) { model in
                            Text(model).tag(model)
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
    }
    
    private var defaultModelBinding: Binding<String> {
        Binding(
            get: { appSettings.first?.defaultModel ?? "" },
            set: { newValue in
                if let settings = appSettings.first {
                    settings.defaultModel = newValue
                } else {
                    let newSettings = AppSettings(defaultModel: newValue)
                    modelContext.insert(newSettings)
                }
                try? modelContext.save()
                // Update viewModel's selected model if this is a new chat
                if chatViewModel.isNewChat {
                    chatViewModel.selectedModel = newValue
                }
            }
        )
    }
}

// End of file. No additional code.

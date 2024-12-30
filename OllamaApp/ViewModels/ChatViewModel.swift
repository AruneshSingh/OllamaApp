import SwiftUI
import SwiftData

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var availableModels: [String] = []
    @Published var selectedModel: String = ""
    @Published var isLoading = false
    @Published var isNewChat: Bool = true
    
    private let baseURL = "http://localhost:11434/api"
    private let modelContext: ModelContext
    var currentSessionId: UUID?
    
    var chatHistory: [ChatSession] {
        let descriptor = FetchDescriptor<ChatSession>(sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)])
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        return sessions
    }
    
    init(container: ModelContainer) {
        self.modelContext = container.mainContext
        loadSettings()
        fetchAvailableModels()
    }
    
    private func loadSettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            if !settings.defaultModel.isEmpty && availableModels.contains(settings.defaultModel) {
                selectedModel = settings.defaultModel
            } else if let firstModel = availableModels.first {
                selectedModel = firstModel
            }
        }
    }
    
    func fetchAvailableModels() {
        guard let url = URL(string: "\(baseURL)/tags") else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
                await MainActor.run {
                    self.availableModels = response.models.map { $0.name }
                    if selectedModel.isEmpty, let firstModel = self.availableModels.first {
                        self.selectedModel = firstModel
                    }
                }
            } catch {
                print("Error fetching models: \(error)")
            }
        }
    }
    
    func sendMessage(content: String, model: String) {
        let userMessage = Message(id: UUID(), role: "user", content: content)
        modelContext.insert(userMessage)
        messages.append(userMessage)
        saveChatSession()
        isLoading = true
        
        guard let url = URL(string: "\(baseURL)/generate") else { return }
        let requestBody = GenerateRequest(model: model, prompt: content, stream: true)
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(requestBody)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let responseString = String(decoding: data, as: UTF8.self)
                var fullResponse = ""
                
                responseString.split(separator: "\n").forEach { line in
                    if let data = line.data(using: .utf8),
                       let response = try? JSONDecoder().decode(GenerateResponse.self, from: data) {
                        fullResponse += response.response
                    }
                }
                
                let assistantMessage = Message(id: UUID(), role: "assistant", content: fullResponse)
                modelContext.insert(assistantMessage)
                messages.append(assistantMessage)
                saveChatSession()
                objectWillChange.send()
                
            } catch {
                print("Error sending message: \(error)")
            }
            isLoading = false
        }
    }
    
    func saveChatSession() {
        guard !selectedModel.isEmpty else { return }
        
        let now = Date()
        let title = ChatSession.generateTitle(from: messages)
        
        if let currentId = currentSessionId,
           let existingSession = try? modelContext.fetch(FetchDescriptor<ChatSession>(
            predicate: #Predicate<ChatSession> { $0.id == currentId }
           )).first {
            // Update existing session
            existingSession.lastUpdated = now
            existingSession.title = title
            existingSession.modelName = selectedModel
            existingSession.messages = messages
            messages.forEach { $0.chat = existingSession }
        } else {
            // Create new session
            let newSession = ChatSession(
                lastUpdated: now,
                title: title,
                modelName: selectedModel,
                messages: messages
            )
            currentSessionId = newSession.id
            modelContext.insert(newSession)
        }
        
        try? modelContext.save()
        isNewChat = false
        objectWillChange.send()
    }
    
    func loadSession(_ session: ChatSession) {
        messages = session.messages
        currentSessionId = session.id
        selectedModel = availableModels.contains(session.modelName) ? session.modelName : selectedModel
        isNewChat = false
        objectWillChange.send()
    }
    
    func startNewChat() {
        messages = []
        currentSessionId = nil
        isNewChat = true
        // Load default model from settings
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? modelContext.fetch(descriptor).first,
           !settings.defaultModel.isEmpty && availableModels.contains(settings.defaultModel) {
            selectedModel = settings.defaultModel
        } else if let firstModel = availableModels.first {
            selectedModel = firstModel
        }
        objectWillChange.send()
    }
    
    func clearAllHistory() {
        let descriptor = FetchDescriptor<ChatSession>()
        if let sessions = try? modelContext.fetch(descriptor) {
            sessions.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }
}

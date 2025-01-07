import SwiftUI
import SwiftData

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var availableModels: [String] = []
    @Published var selectedModel: String = ""
    @Published var isLoading = false
    @Published var isNewChat: Bool = true
    @Published var connectionError: String? = nil
    
    private let baseURL = "http://localhost:11434/api"
    let container: ModelContainer
    var currentSessionId: UUID?
    
    var chatHistory: [ChatSession] {
        let descriptor = FetchDescriptor<ChatSession>(sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)])
        let sessions = (try? container.mainContext.fetch(descriptor)) ?? []
        return sessions
    }
    
    init(container: ModelContainer) {
        self.container = container
        Task {
            await fetchModelsAndLoadDefault()
        }
    }
    
    private func fetchModelsAndLoadDefault() async {
        // First fetch models
        let models = await fetchModelsFromOllama()
        await MainActor.run {
            self.availableModels = models
        }
        
        // Then load the default model from stored settings
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let settings = try container.mainContext.fetch(descriptor)
            
            await MainActor.run {
                if let firstSettings = settings.first,
                   !firstSettings.defaultModel.isEmpty,
                   models.contains(firstSettings.defaultModel) {
                    self.selectedModel = firstSettings.defaultModel
                    print("[ChatViewModel] Loaded stored default model: \(firstSettings.defaultModel)")
                } else if let firstModel = models.first {
                    // If no valid stored default, use first available model
                    self.selectedModel = firstModel
                    print("[ChatViewModel] Using first available model: \(firstModel)")
                    
                    // Create or update settings
                    if let existingSettings = settings.first {
                        existingSettings.defaultModel = firstModel
                        existingSettings.lastUpdated = Date()
                    } else {
                        let newSettings = AppSettings(defaultModel: firstModel)
                        container.mainContext.insert(newSettings)
                    }
                    try? container.mainContext.save()
                }
            }
        } catch {
            print("[ChatViewModel] Error loading default model: \(error)")
            if let firstModel = models.first {
                await MainActor.run {
                    self.selectedModel = firstModel
                }
            }
        }
    }
    

    
    func updateDefaultModel(_ model: String) {
        guard !model.isEmpty, availableModels.contains(model) else { return }
        
        print("[ChatViewModel] Updating default model to: \(model)")
        let context = container.mainContext
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let settings = try context.fetch(descriptor)
            let settingsToUpdate: AppSettings
            
            if let existingSettings = settings.first {
                settingsToUpdate = existingSettings
            } else {
                settingsToUpdate = AppSettings(defaultModel: model)
                context.insert(settingsToUpdate)
            }
            
            settingsToUpdate.defaultModel = model
            settingsToUpdate.lastUpdated = Date()
            try context.save()
            
            print("[ChatViewModel] Successfully saved default model: \(model)")
            
            // Only update selectedModel if this is a new chat
            if isNewChat {
                selectedModel = model
            }
            
            // Force a view update
            objectWillChange.send()
        } catch {
            print("[ChatViewModel] Error saving default model: \(error)")
        }
    }
    
    private func fetchAvailableModels() async {
        let context = container.mainContext
        let descriptor = FetchDescriptor<AvailableModels>(sortBy: [SortDescriptor(\AvailableModels.lastUpdated, order: .reverse)])
        
        do {
            let storedModels = try context.fetch(descriptor).first
            
            if let storedModels = storedModels,
               storedModels.lastUpdated.timeIntervalSinceNow > -3600 {
                self.availableModels = storedModels.models
                return
            }
            
            let models = await fetchModelsFromOllama()
            self.availableModels = models
            
            if let storedModels = storedModels {
                storedModels.models = models
                storedModels.lastUpdated = Date()
            } else {
                let newStoredModels = AvailableModels(models: models, lastUpdated: Date())
                context.insert(newStoredModels)
            }
            try context.save()
            
        } catch {
            print("Error loading models: \(error)")
            self.availableModels = await fetchModelsFromOllama()
        }
    }
    
    private func fetchModelsFromOllama() async -> [String] {
        guard let url = URL(string: "\(baseURL)/tags") else {
            await MainActor.run {
                self.connectionError = "Invalid URL"
            }
            return []
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.connectionError = "Invalid server response"
                }
                return []
            }
            
            guard httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.connectionError = "Server error: \(httpResponse.statusCode)"
                }
                return []
            }
            
            let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
            await MainActor.run {
                self.connectionError = nil
            }
            return modelsResponse.models.map { $0.name }
        } catch {
            await MainActor.run {
                self.connectionError = "Error fetching models: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    private func checkOllamaConnection() async -> Bool {
        guard let url = URL(string: "\(baseURL)/tags") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            await MainActor.run {
                self.connectionError = "Cannot connect to Ollama. Make sure it's running on localhost:11434"
            }
            return false
        }
    }

    private func extractTag(from content: String) -> (tag: String?, message: String) {
        let words = content.split(separator: " ")
        
        for word in words {
            for tag in TaggedModel.allCases {
                if word == tag.rawValue {
                    // Remove the tag from the content
                    let cleanMessage = content.replacingOccurrences(of: tag.rawValue, with: "").trimmingCharacters(in: .whitespaces)
                    return (tag.rawValue, cleanMessage)
                }
            }
        }
        return (nil, content)
    }
    
    private func getModelForTag(_ tag: String?) -> String {
        guard let tag = tag else { return selectedModel }
        
        let descriptor = FetchDescriptor<AppSettings>()
        guard let settings = try? container.mainContext.fetch(descriptor).first else {
            return selectedModel
        }
        
        let tagModel = settings.getModelForTag(tag)
        return !tagModel.isEmpty ? tagModel : selectedModel
    }
    
    private struct GenerateRequest: Codable {
        let model: String
        let prompt: String
        let stream: Bool
        let context: [Int]?
    }

    private struct GenerateResponse: Codable {
        let response: String
        let context: [Int]?
        let done: Bool
    }

    private var lastContext: [Int]? {
        get {
            if let currentId = currentSessionId,
               let session = try? container.mainContext.fetch(FetchDescriptor<ChatSession>(
                predicate: #Predicate<ChatSession> { $0.id == currentId }
               )).first {
                return session.currentContext
            }
            return nil
        }
        set {
            if let currentId = currentSessionId,
               let session = try? container.mainContext.fetch(FetchDescriptor<ChatSession>(
                predicate: #Predicate<ChatSession> { $0.id == currentId }
               )).first {
                session.currentContext = newValue
                try? container.mainContext.save()
            }
        }
    }

    func sendMessage(content: String, model: String? = nil) {
        let (detectedTag, cleanMessage) = extractTag(from: content)
        let modelToUse = model ?? getModelForTag(detectedTag)
        
        // Update the selectedModel for the current chat
        self.selectedModel = modelToUse
        
        let userMessage = Message(id: UUID(), role: "user", content: cleanMessage)
        container.mainContext.insert(userMessage)
        messages.append(userMessage)
        saveChatSession()
        isLoading = true
        connectionError = nil
        
        guard let url = URL(string: "\(baseURL)/generate") else {
            connectionError = "Invalid URL"
            isLoading = false
            return
        }
        
        let requestBody = GenerateRequest(
            model: modelToUse,
            prompt: cleanMessage,
            stream: true,
            context: lastContext
        )
        
        Task {
            guard await checkOllamaConnection() else {
                isLoading = false
                return
            }
            
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(requestBody)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    connectionError = "Invalid server response"
                    isLoading = false
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    connectionError = "Server error: \(httpResponse.statusCode)"
                    isLoading = false
                    return
                }
                
                let responseString = String(decoding: data, as: UTF8.self)
                var fullResponse = ""
                
                responseString.split(separator: "\n").forEach { line in
                    if let data = line.data(using: .utf8),
                       let generateResponse = try? JSONDecoder().decode(GenerateResponse.self, from: data) {
                        fullResponse += generateResponse.response
                        if let context = generateResponse.context {
                            lastContext = context // This will now update the last message's context
                        }
                    }
                }
                
                let assistantMessage = Message(
                    id: UUID(),
                    role: "assistant",
                    content: fullResponse,
                    context: lastContext // Store context with the message
                )
                container.mainContext.insert(assistantMessage)
                messages.append(assistantMessage)
                saveChatSession()
                objectWillChange.send()
                
            } catch {
                connectionError = "Error sending message: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    func saveChatSession() {
        guard !selectedModel.isEmpty else { return }
        
        let now = Date()
        let title = ChatSession.generateTitle(from: messages)
        
        if let currentId = currentSessionId,
           let existingSession = try? container.mainContext.fetch(FetchDescriptor<ChatSession>(
            predicate: #Predicate<ChatSession> { $0.id == currentId }
           )).first {
            existingSession.lastUpdated = now
            existingSession.title = title
            existingSession.modelName = selectedModel
            existingSession.messages = messages
            messages.forEach { $0.chat = existingSession }
        } else {
            let newSession = ChatSession(
                lastUpdated: now,
                title: title,
                modelName: selectedModel,
                messages: messages
            )
            currentSessionId = newSession.id
            container.mainContext.insert(newSession)
        }
        
        try? container.mainContext.save()
        isNewChat = false
        objectWillChange.send()
    }
    
    func loadSession(_ session: ChatSession) {
        messages = session.messages
        currentSessionId = session.id
        selectedModel = availableModels.contains(session.modelName) ? session.modelName : selectedModel
        isNewChat = false
        // lastContext will now be automatically set from the last message's context
        objectWillChange.send()
    }
    
    func startNewChat() {
        messages = []
        currentSessionId = nil
        isNewChat = true
        lastContext = nil
        
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? container.mainContext.fetch(descriptor).first,
           !settings.defaultModel.isEmpty,
           availableModels.contains(settings.defaultModel) {
            selectedModel = settings.defaultModel
        }
        objectWillChange.send()
    }
    
    func clearAllHistory() {
        let descriptor = FetchDescriptor<ChatSession>()
        if let sessions = try? container.mainContext.fetch(descriptor) {
            sessions.forEach { container.mainContext.delete($0) }
            try? container.mainContext.save()
        }
    }
}

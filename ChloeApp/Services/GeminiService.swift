import Foundation

enum GeminiError: Error, LocalizedError {
    case noAPIKey
    case timeout
    case apiError(Int, String)
    case emptyResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "API key not configured"
        case .timeout: return "Chloe is taking too long to respond. Please try again."
        case .apiError(let code, let msg): return "API error (\(code)): \(msg)"
        case .emptyResponse: return "I'm having a moment — can you try again?"
        case .decodingFailed: return "Failed to parse response"
        }
    }
}

class GeminiService {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    private let timeoutInterval: TimeInterval = 15

    private var apiKey: String {
        Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
    }

    private init() {}

    // MARK: - Chat

    func sendMessage(
        messages: [Message],
        systemPrompt: String,
        userFacts: [String] = [],
        temperature: Double = 0.8
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw GeminiError.noAPIKey }

        var systemInstruction = systemPrompt
        if !userFacts.isEmpty {
            systemInstruction += "\n\nWhat you know about this user:\n\(userFacts.joined(separator: "\n"))"
        }

        // Session handover: inject last session context on first message of new conversation
        let isNewConversation = messages.count <= 1
        if isNewConversation, let lastSummary = StorageService.shared.loadLatestSummary() {
            systemInstruction += """

            \n<session_context>
            The user's last session was about: "\(lastSummary)".
            If relevant, casually mention it early in the conversation. E.g., "How did that dinner go?"
            Do not force it if the user starts a completely new topic.
            </session_context>
            """
        }

        // Pattern insight injection (skip on first message of new conversation to avoid overload)
        if !isNewConversation, let insight = StorageService.shared.popInsight() {
            systemInstruction += """

            \n<internal_insight>
            The Analyst detected a pattern: "\(insight)".
            Wait for a natural moment in this conversation to gently point this out to the user.
            Do not force it, but use it to show you are listening deeply.
            </internal_insight>
            """
        }

        let recentMessages = Array(messages.suffix(MAX_CONVERSATION_HISTORY))

        let geminiContents = recentMessages.map { msg -> [String: Any] in
            [
                "role": msg.role == .user ? "user" : "model",
                "parts": [["text": msg.text]],
            ]
        }

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemInstruction]],
            ],
            "contents": geminiContents,
            "generationConfig": [
                "temperature": temperature,
                "topP": 0.9,
                "maxOutputTokens": 1024,
            ],
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"],
            ],
        ]

        let data = try await makeRequest(body: body)
        return try extractText(from: data) ?? "I'm having a moment — can you try again?"
    }

    // MARK: - Analyze Conversation

    func analyzeConversation(
        messages: [Message],
        userFacts: [String] = [],
        lastSummary: String? = nil,
        currentVibe: VibeScore? = nil,
        displayName: String? = nil
    ) async throws -> AnalystResult {
        guard !apiKey.isEmpty else { throw GeminiError.noAPIKey }

        let conversationText = messages
            .map { "\($0.role == .user ? "User" : "Chloe"): \($0.text)" }
            .joined(separator: "\n\n")

        // Build structured context dossier
        let dossier = """
        <context_dossier>
          USER NAME: \(displayName ?? "Unknown")
          CURRENT VIBE SCORE: \(currentVibe?.rawValue ?? "UNKNOWN")
          KNOWN FACTS: \(userFacts.joined(separator: "; "))
          LAST SESSION SUMMARY: \(lastSummary ?? "No previous session")
        </context_dossier>
        """

        let fullText = dossier + "\n\n--- CURRENT CONVERSATION ---\n" + conversationText

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": Prompts.analyst]],
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": fullText]],
                ],
            ],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 1024,
                "responseMimeType": "application/json",
            ],
        ]

        let data = try await makeRequest(body: body)
        guard let text = try extractText(from: data) else {
            throw GeminiError.emptyResponse
        }

        guard let jsonData = text.data(using: .utf8) else {
            throw GeminiError.decodingFailed
        }

        return try JSONDecoder().decode(AnalystResult.self, from: jsonData)
    }

    // MARK: - Generate Affirmation

    func generateAffirmation(
        displayName: String,
        preferences: OnboardingPreferences?,
        archetype: UserArchetype?
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw GeminiError.noAPIKey }

        let prompt = buildAffirmationPrompt(
            displayName: displayName,
            preferences: preferences,
            archetype: archetype
        )

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": prompt]],
                ],
            ],
            "generationConfig": [
                "temperature": 0.9,
                "maxOutputTokens": 256,
            ],
        ]

        let data = try await makeRequest(body: body)
        let text = try extractText(from: data) ?? "You are the prize. Act accordingly."
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Generate Title

    func generateTitle(for messageText: String) async throws -> String {
        guard !apiKey.isEmpty else { throw GeminiError.noAPIKey }

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": "\(Prompts.titleGeneration)\n\n\(messageText)"]],
                ],
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 32,
            ],
        ]

        let data = try await makeRequest(body: body)
        let text = try extractText(from: data) ?? "New Conversation"
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private Helpers

    private func makeRequest(body: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.noAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw GeminiError.apiError(httpResponse.statusCode, errorText)
            }
            return data
        } catch is URLError {
            throw GeminiError.timeout
        }
    }

    private func extractText(from data: Data) throws -> String? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return nil
        }
        return text
    }
}

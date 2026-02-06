import Foundation
import UIKit

enum GeminiError: Error, LocalizedError {
    case noAPIKey
    case timeout
    case noConnection
    case apiError(Int, String)
    case emptyResponse
    case decodingFailed
    case routerInvalidResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "API key not configured"
        case .timeout: return "Chloe is taking too long to respond. Please try again."
        case .noConnection: return "No internet connection. Please check your network and try again."
        case .apiError(let code, let msg): return "API error (\(code)): \(msg)"
        case .emptyResponse: return "I'm having a moment — can you try again?"
        case .decodingFailed: return "Failed to parse response"
        case .routerInvalidResponse: return "Router returned invalid response"
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

    // MARK: - Agentic Response (v2)

    /// Send a message to the Strategist expecting a structured JSON response (v2.2 - Stability Fix)
    func sendStrategistMessage(
        messages: [Message],
        systemPrompt: String,
        userFacts: [String] = [],
        lastSummary: String? = nil,
        insight: String? = nil,
        temperature: Double = 0.7,
        userId: String? = nil,
        conversationId: String? = nil,
        attempt: Int = 1  // FIX 2: Retry logic
    ) async throws -> StrategistResponse {
        guard !apiKey.isEmpty else { throw GeminiError.noAPIKey }

        // Build system instruction with facts
        var systemInstruction = systemPrompt
        if !userFacts.isEmpty {
            systemInstruction += "\n\n<user_facts>\n" + userFacts.joined(separator: "\n") + "\n</user_facts>"
        }
        if let summary = lastSummary {
            systemInstruction += "\n\n<last_session_summary>\n\(summary)\n</last_session_summary>"
        }
        if let insight = insight {
            systemInstruction += "\n\n<insight_to_mention>\n\(insight)\n</insight_to_mention>"
        }

        let recentMessages = Array(messages.suffix(MAX_CONVERSATION_HISTORY))

        // Convert messages to Gemini format (including images for latest message)
        let geminiContents: [[String: Any]] = recentMessages.enumerated().map { index, msg in
            var parts: [[String: Any]] = []

            // Only attach image data for the latest message to save tokens
            let isLatest = index == recentMessages.count - 1
            if let imageUri = msg.imageUri {
                if isLatest, let imageData = loadImageData(from: imageUri) {
                    parts.append([
                        "inlineData": [
                            "mimeType": "image/jpeg",
                            "data": imageData.base64EncodedString()
                        ]
                    ])
                } else if !isLatest {
                    parts.append(["text": "[User shared an image]"])
                }
            }

            if !msg.text.isEmpty {
                parts.append(["text": msg.text])
            }

            // Ensure at least one part exists
            if parts.isEmpty {
                parts.append(["text": "[Image]"])
            }

            return [
                "role": msg.role == .user ? "user" : "model",
                "parts": parts
            ]
        }

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemInstruction]]],
            "contents": geminiContents,
            "generationConfig": [
                "temperature": temperature,
                "maxOutputTokens": 2048,
                "responseMimeType": "application/json"  // Force JSON output
            ]
        ]

        let data = try await makeRequest(body: body)

        guard let text = try extractText(from: data) else {
            throw GeminiError.emptyResponse
        }

        #if DEBUG
        print("[GeminiService] Raw strategist response (attempt \(attempt)): \(text.prefix(500))...")
        #endif

        // FIX 4: Strip markdown wrappers before parsing
        let cleanedText = stripMarkdownWrapper(text)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw GeminiError.decodingFailed
        }

        do {
            return try JSONDecoder().decode(StrategistResponse.self, from: jsonData)
        } catch {
            #if DEBUG
            print("[GeminiService] JSON decode failed (attempt \(attempt)): \(error)")
            #endif

            // FIX 5: Analytics tracking (TODO: Wire up TelemetryDeck when configured)
            // TelemetryDeck.signal("strategist_json_failure", parameters: ["attempt": "\(attempt)"])

            // FIX 2: Retry once before falling back
            if attempt < 2 {
                #if DEBUG
                print("[GeminiService] Retrying strategist request...")
                #endif
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                return try await sendStrategistMessage(
                    messages: messages,
                    systemPrompt: systemPrompt,
                    userFacts: userFacts,
                    lastSummary: lastSummary,
                    insight: insight,
                    temperature: temperature,
                    userId: userId,
                    conversationId: conversationId,
                    attempt: attempt + 1
                )
            }

            // Fallback after 2 attempts: Create response from raw text
            #if DEBUG
            print("[GeminiService] All retries exhausted. Falling back to raw text.")
            #endif
            return StrategistResponse(
                internalThought: InternalThought(
                    userVibe: "MEDIUM",
                    manBehaviorAnalysis: "JSON parsing failed after \(attempt) attempts",
                    strategySelection: "Fallback to raw text"
                ),
                response: ResponseContent(text: cleanedText, options: nil)
            )
        }
    }

    /// Classify a message using the Context Router (with retry logic matching strategist)
    func classifyMessage(
        message: String,
        systemPrompt: String = Prompts.router,
        attempt: Int = 1
    ) async throws -> RouterClassification {
        guard !apiKey.isEmpty else { throw GeminiError.noAPIKey }

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": [
                ["role": "user", "parts": [["text": message]]]
            ],
            "generationConfig": [
                "temperature": 0.1,  // Low temp for classification
                "maxOutputTokens": 256,
                "responseMimeType": "application/json"
            ]
        ]

        let data = try await makeRequest(body: body)

        guard let text = try extractText(from: data) else {
            throw GeminiError.emptyResponse
        }

        #if DEBUG
        print("[GeminiService] Router classification (attempt \(attempt)): \(text)")
        #endif

        let cleanedText = stripMarkdownWrapper(text)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw GeminiError.decodingFailed
        }

        do {
            return try JSONDecoder().decode(RouterClassification.self, from: jsonData)
        } catch {
            #if DEBUG
            print("[GeminiService] Router decode failed (attempt \(attempt)): \(error)")
            #endif

            if attempt < 2 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                return try await classifyMessage(
                    message: message,
                    systemPrompt: systemPrompt,
                    attempt: attempt + 1
                )
            }

            throw GeminiError.routerInvalidResponse
        }
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
        guard !apiKey.isEmpty, let url = URL(string: baseURL) else {
            throw GeminiError.noAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = timeoutInterval
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw GeminiError.apiError(httpResponse.statusCode, errorText)
            }
            return data
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw GeminiError.noConnection
            default:
                throw GeminiError.timeout
            }
        }
    }

    private func loadImageData(from path: String) -> Data? {
        guard let image = UIImage(contentsOfFile: path) else { return nil }
        // Resize if needed to stay under Gemini's ~4MB per-image limit
        let maxDimension: CGFloat = 1024
        let size = image.size
        var targetImage = image
        if size.width > maxDimension || size.height > maxDimension {
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            targetImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
        return targetImage.jpegData(compressionQuality: 0.8)
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

    /// Strip markdown code block wrappers from LLM output (FIX 4: v2.2 Stability)
    private func stripMarkdownWrapper(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove ```json ... ``` wrapper
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }

        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Protocol Conformance

extension GeminiService: GeminiServiceProtocol {}

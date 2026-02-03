import Foundation

enum PortkeyError: LocalizedError {
    case noAPIKey
    case noVirtualKey
    case apiError(Int, String)
    case emptyResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "Portkey API key not configured"
        case .noVirtualKey: return "Portkey virtual key not configured"
        case .apiError(let code, let msg): return "Portkey error (\(code)): \(msg)"
        case .emptyResponse: return "Empty response from Portkey"
        case .decodingFailed: return "Failed to decode Portkey response"
        }
    }
}

struct PortkeyMessage: Codable {
    let role: String
    let content: String
}

/// Routes AI calls through Portkey for logging, analytics, and observability
class PortkeyService {
    static let shared = PortkeyService()

    private let baseURL = "https://api.portkey.ai/v1/chat/completions"
    private let feedbackURL = "https://api.portkey.ai/v1/feedback"
    private let timeoutInterval: TimeInterval = 30

    /// Last trace ID from a Portkey call (for feedback correlation)
    private(set) var lastTraceId: String?

    private var apiKey: String {
        Bundle.main.infoDictionary?["PORTKEY_API_KEY"] as? String ?? ""
    }

    private var virtualKey: String {
        Bundle.main.infoDictionary?["PORTKEY_VIRTUAL_KEY"] as? String ?? ""
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && !virtualKey.isEmpty
    }

    private init() {}

    // MARK: - Chat via Portkey Gateway

    /// Send chat messages through Portkey to Gemini
    func chat(
        messages: [PortkeyMessage],
        systemPrompt: String,
        metadata: [String: String] = [:],
        temperature: Double = 0.8
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw PortkeyError.noAPIKey }
        guard !virtualKey.isEmpty else { throw PortkeyError.noVirtualKey }

        guard let url = URL(string: baseURL) else {
            throw PortkeyError.noAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-portkey-api-key")
        request.setValue(virtualKey, forHTTPHeaderField: "x-portkey-virtual-key")
        request.timeoutInterval = timeoutInterval

        // Add metadata headers for tracking
        for (key, value) in metadata {
            request.setValue(value, forHTTPHeaderField: "x-portkey-metadata-\(key)")
        }

        // Convert to OpenAI-compatible format for Portkey
        var allMessages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]

        for msg in messages {
            allMessages.append([
                "role": msg.role,
                "content": msg.content
            ])
        }

        // Model format: @{virtualKey}/{model}
        let model = "@\(virtualKey)/gemini-2.0-flash"

        let body: [String: Any] = [
            "model": model,
            "messages": allMessages,
            "max_tokens": 1024
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Extract trace ID from response headers
        if let httpResponse = response as? HTTPURLResponse {
            // Try multiple header name formats (case-insensitive lookup)
            for (key, value) in httpResponse.allHeaderFields {
                if let keyStr = key as? String,
                   keyStr.lowercased() == "x-portkey-trace-id",
                   let valueStr = value as? String {
                    lastTraceId = valueStr
                    #if DEBUG
                    NSLog("[Portkey] Captured trace ID: %@", valueStr)
                    #endif
                    break
                }
            }

            if httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw PortkeyError.apiError(httpResponse.statusCode, errorText)
            }
        }

        // Parse OpenAI-compatible response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw PortkeyError.emptyResponse
        }

        return content
    }

    // MARK: - Feedback

    /// Send feedback to Portkey for a specific trace
    func sendFeedback(traceId: String, rating: String) async throws {
        #if DEBUG
        NSLog("[Portkey] Sending feedback - traceId: %@, rating: %@", traceId, rating)
        #endif

        guard !apiKey.isEmpty else {
            #if DEBUG
            NSLog("[Portkey] ERROR: No API key for feedback")
            #endif
            return
        }

        guard let url = URL(string: feedbackURL) else {
            #if DEBUG
            NSLog("[Portkey] ERROR: Invalid feedback URL")
            #endif
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-portkey-api-key")

        // Value should be an integer: positive for good, negative for bad
        let numericValue = rating == "1" ? 1 : -1

        let body: [String: Any] = [
            "trace_id": traceId,
            "value": numericValue
        ]

        #if DEBUG
        NSLog("[Portkey] Feedback request body: %@", String(describing: body))
        #endif

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            let responseText = String(data: data, encoding: .utf8) ?? "No body"
            NSLog("[Portkey] Feedback response: status=%d, body=%@", httpResponse.statusCode, responseText)
        }
        #else
        _ = data
        _ = response
        #endif
    }
}

//
//  DeepseekAIService.swift
//  thinqsync
//
//  Created by Claude on 04/11/2025.
//

import Foundation
import Combine

@MainActor
class DeepseekAIService: ObservableObject {
    static let shared = DeepseekAIService()

    private let apiEndpoint = "https://openrouter.ai/api/v1/chat/completions"
    private let apiKeyUserDefaultsKey = "DeepseekAPIKey"
    private let modelUserDefaultsKey = "DeepseekModelName"

    @Published var isConfigured: Bool = false
    @Published var isProcessing: Bool = false

    // Available models on OpenRouter
    // Check openrouter.ai/models for current list
    // NOTE: :free models may be rate-limited, paid models are more reliable
    static let availableModels = [
        "deepseek/deepseek-chat",           // Most stable (RECOMMENDED)
        "deepseek/deepseek-r1",             // Latest R1 (requires credits)
        "deepseek/deepseek-coder",          // For code (requires credits)
        "deepseek/deepseek-r1:free",        // Free but often rate-limited
        "deepseek/deepseek-chat:free"       // Free but often rate-limited
    ]

    private init() {
        checkConfiguration()
    }

    var selectedModel: String {
        get {
            UserDefaults.standard.string(forKey: modelUserDefaultsKey) ?? "deepseek/deepseek-chat"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: modelUserDefaultsKey)
        }
    }

    // MARK: - API Key Management

    var apiKey: String? {
        get {
            UserDefaults.standard.string(forKey: apiKeyUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: apiKeyUserDefaultsKey)
            checkConfiguration()
        }
    }

    private func checkConfiguration() {
        isConfigured = apiKey != nil && !apiKey!.isEmpty
    }

    func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: apiKeyUserDefaultsKey)
        checkConfiguration()
    }

    // MARK: - AI Operations

    enum AIOperation {
        case improveWriting
        case summarize
        case expand
        case fixGrammar

        var systemPrompt: String {
            switch self {
            case .improveWriting:
                return "You are a professional writing assistant. Improve the following text by enhancing its clarity, style, and flow while maintaining the original meaning and tone. Return ONLY the improved text, without any explanations or additional commentary."
            case .summarize:
                return "You are a summarization expert. Create a concise, clear summary of the following text that captures the key points. Return ONLY the summary, without any introductory phrases or additional commentary."
            case .expand:
                return "You are a writing assistant. Expand the following text by adding more detail, context, and explanation while maintaining the original meaning and tone. Return ONLY the expanded text, without any explanations or additional commentary."
            case .fixGrammar:
                return "You are a grammar expert. Fix all grammatical errors, spelling mistakes, and punctuation issues in the following text while preserving the original meaning and style. Return ONLY the corrected text, without any explanations or additional commentary."
            }
        }
    }

    func processText(_ text: String, operation: AIOperation) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }

        guard !text.isEmpty else {
            throw AIError.emptyText
        }

        isProcessing = true
        defer { isProcessing = false }

        // Prepare request
        guard let url = URL(string: apiEndpoint) else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("https://thinqsync.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("ThinqSync/1.0", forHTTPHeaderField: "X-Title")

        let requestBody: [String: Any] = [
            "model": selectedModel,
            "messages": [
                ["role": "system", "content": operation.systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Log request for debugging
        print("🔵 OpenRouter Request:")
        print("   Model: \(selectedModel)")
        print("   Endpoint: \(apiEndpoint)")
        print("   Text length: \(text.count) chars")

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from response with detailed info
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Log full error response for debugging
                print("❌ OpenRouter Error Response: \(errorJson)")

                // Try to extract detailed error message
                if let error = errorJson["error"] as? [String: Any] {
                    let message = error["message"] as? String ?? "Unknown error"
                    let code = error["code"] as? Int ?? 0

                    // Check for rate limiting (429)
                    if code == 429 {
                        // Check if it's the free model being rate-limited
                        if selectedModel.contains(":free") {
                            throw AIError.rateLimitedFreeModel
                        } else {
                            throw AIError.rateLimited
                        }
                    }

                    // Other errors
                    if code > 0 {
                        throw AIError.apiError("\(message) (Code: \(code))")
                    } else {
                        throw AIError.apiError(message)
                    }
                } else if let message = errorJson["message"] as? String {
                    throw AIError.apiError(message)
                }
            }

            // If we can't parse the error, show HTTP status and raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Raw Error Response: \(responseString)")
                throw AIError.apiError("HTTP \(httpResponse.statusCode): \(responseString.prefix(200))")
            }

            throw AIError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON response")
            throw AIError.invalidResponse
        }

        // Log successful response structure for debugging
        print("✅ OpenRouter Response received")
        print("   Keys: \(json.keys.joined(separator: ", "))")

        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("❌ Response structure invalid")
            print("   Full response: \(json)")
            throw AIError.invalidResponse
        }

        print("✅ AI Response: \(content.prefix(100))...")
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Error Handling

    enum AIError: LocalizedError {
        case noAPIKey
        case emptyText
        case invalidURL
        case invalidResponse
        case apiError(String)
        case rateLimited
        case rateLimitedFreeModel

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key configured. Please add your OpenRouter API key in AI Settings."
            case .emptyText:
                return "No text selected. Please select text to process."
            case .invalidURL:
                return "Invalid API endpoint URL."
            case .invalidResponse:
                return "Invalid response from AI service."
            case .apiError(let message):
                return "API Error: \(message)"
            case .rateLimited:
                return "Rate limit exceeded. Please wait a moment and try again."
            case .rateLimitedFreeModel:
                return "Free model is temporarily rate-limited. Please:\n\n1. Wait 30-60 seconds and try again\n2. OR switch to 'deepseek/deepseek-chat' (paid model) in AI Settings\n3. OR add credits to your OpenRouter account"
            }
        }
    }
}

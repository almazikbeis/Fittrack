//
//  AnthropicService.swift
//  FitnessApp
//
//  Lightweight wrapper around the Anthropic Messages API.
//

import Foundation

// MARK: - Request / Response models

private struct MessageParam: Encodable {
    let role: String
    let content: String
}

private struct RequestBody: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [MessageParam]
}

private struct ResponseBody: Decodable {
    struct Block: Decodable {
        let type: String
        let text: String?
    }
    let content: [Block]
}

// MARK: - Errors

enum AnthropicError: LocalizedError {
    case noKey
    case httpError(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noKey:            return "Введите API-ключ Anthropic в настройках тренера"
        case .httpError(let c): return "Ошибка сервера: \(c)"
        case .emptyResponse:    return "Пустой ответ от сервера"
        }
    }
}

// MARK: - Service

final class AnthropicService {

    static let shared = AnthropicService()
    private init() {}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "coach_anthropic_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "coach_anthropic_key") }
    }

    var hasKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    func send(
        messages: [(role: String, content: String)],
        system: String
    ) async throws -> String {

        guard hasKey else { throw AnthropicError.noKey }

        let body = RequestBody(
            model: "claude-haiku-4-5-20251001",
            max_tokens: 512,
            system: system,
            messages: messages.map { MessageParam(role: $0.role, content: $0.content) }
        )

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json",        forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey,                    forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",              forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AnthropicError.httpError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text else {
            throw AnthropicError.emptyResponse
        }
        return text
    }
}

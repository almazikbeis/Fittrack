//
//  FoodRecognitionService.swift
//  FitnessApp
//
//  Uses OpenAI GPT-4o-mini Vision to analyse a food photo
//  and return estimated КБЖУ (calories / protein / fat / carbs).
//

import Foundation
import UIKit

// MARK: - Result Model

struct FoodAnalysisResult {
    let name:             String
    let estimatedWeightG: Double   // portion size in grams
    let caloriesPer100g:  Double
    let proteinPer100g:   Double
    let fatPer100g:       Double
    let carbsPer100g:     Double
    let confidence:       Double   // 0.0 – 1.0

    // Computed for the given portion
    func calories(for grams: Double) -> Double { caloriesPer100g * grams / 100 }
    func protein(for grams: Double)  -> Double { proteinPer100g  * grams / 100 }
    func fat(for grams: Double)      -> Double { fatPer100g      * grams / 100 }
    func carbs(for grams: Double)    -> Double { carbsPer100g    * grams / 100 }
}

// MARK: - Service

final class FoodRecognitionService {
    static let shared = FoodRecognitionService()

    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let model    = "gpt-4o-mini"

    // ── Errors ────────────────────────────────────────────────────────────────

    enum RecognitionError: LocalizedError {
        case imageEncodingFailed
        case networkError(Error)
        case httpError(Int, String)
        case invalidResponse
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .imageEncodingFailed:
                return "Не удалось обработать изображение."
            case .networkError(let e):
                return "Сетевая ошибка: \(e.localizedDescription)"
            case .httpError(let code, let msg):
                return "Ошибка сервера \(code): \(msg)"
            case .invalidResponse:
                return "Неверный ответ от API."
            case .parseError(let raw):
                return "Не удалось разобрать ответ:\n\(raw.prefix(120))"
            }
        }
    }

    // ── Main method ───────────────────────────────────────────────────────────

    func analyze(image: UIImage) async throws -> FoodAnalysisResult {
        // 1. Encode image (resize first to keep payload small)
        guard let resized = image.resizedForAPI(),
              let imageData = resized.jpegData(compressionQuality: 0.75)
        else { throw RecognitionError.imageEncodingFailed }

        let base64 = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64)"

        // 2. Build request body (OpenAI chat/completions format)
        let prompt = """
        You are a professional nutritionist AI. Analyze the food in this photo precisely.
        Return ONLY a valid JSON object — no markdown, no explanation, just raw JSON:
        {"name":"название на русском","estimatedWeightG":200,"caloriesPer100g":150,"proteinPer100g":10,"fatPer100g":5,"carbsPer100g":20,"confidence":0.9}
        Rules:
        - name must be in Russian
        - estimatedWeightG: realistic portion size shown in the photo (grams)
        - caloriesPer100g / proteinPer100g / fatPer100g / carbsPer100g: per 100 g of THIS food
        - confidence: how certain you are (0.0–1.0)
        If you see multiple dishes, pick the most prominent one.
        """

        let body: [String: Any] = [
            "model":      model,
            "max_tokens": 256,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image_url",
                     "image_url": ["url": dataURL, "detail": "low"]],
                    ["type": "text", "text": prompt]
                ]
            ]]
        ]

        // 3. Execute request
        var req = URLRequest(url: URL(string: endpoint)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(AppSecrets.openAIKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw RecognitionError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RecognitionError.httpError(http.statusCode, body)
        }

        // 4. Parse OpenAI response: choices[0].message.content
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let rawText = message["content"] as? String
        else { throw RecognitionError.invalidResponse }

        // Strip any markdown fences the model might add
        var jsonText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonText.hasPrefix("```") {
            let lines = jsonText.components(separatedBy: "\n")
            jsonText = lines.dropFirst().dropLast().joined(separator: "\n")
        }
        // Find first { to last }
        if let start = jsonText.firstIndex(of: "{"),
           let end   = jsonText.lastIndex(of: "}") {
            jsonText = String(jsonText[start...end])
        }

        guard let jsonData = jsonText.data(using: .utf8),
              let r = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { throw RecognitionError.parseError(rawText) }

        return FoodAnalysisResult(
            name:             r["name"]             as? String ?? "Блюдо",
            estimatedWeightG: r["estimatedWeightG"] as? Double ?? 200,
            caloriesPer100g:  r["caloriesPer100g"]  as? Double ?? 0,
            proteinPer100g:   r["proteinPer100g"]   as? Double ?? 0,
            fatPer100g:       r["fatPer100g"]        as? Double ?? 0,
            carbsPer100g:     r["carbsPer100g"]      as? Double ?? 0,
            confidence:       r["confidence"]        as? Double ?? 0.5
        )
    }

    // ── Photo storage helpers ─────────────────────────────────────────────────

    /// Saves image to Documents, returns UUID filename (without extension)
    func savePhoto(_ image: UIImage) -> String? {
        let name = UUID().uuidString
        let url  = documentsURL(for: name)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        try? data.write(to: url, options: .atomic)
        return name
    }

    /// Loads a previously saved photo by its UUID name
    func loadPhoto(named name: String?) -> UIImage? {
        guard let name else { return nil }
        let url = documentsURL(for: name)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func documentsURL(for name: String) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(name).jpg")
    }
}

// MARK: - UIImage helpers

private extension UIImage {
    /// Resize to max 1024 px on longest side to keep API payload small
    func resizedForAPI(maxSide: CGFloat = 1024) -> UIImage? {
        let s = size
        let longest = max(s.width, s.height)
        guard longest > maxSide else { return self }
        let scale = maxSide / longest
        let newSize = CGSize(width: s.width * scale, height: s.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

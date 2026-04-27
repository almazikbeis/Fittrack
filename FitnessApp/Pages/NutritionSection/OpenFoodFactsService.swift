//
//  OpenFoodFactsService.swift
//  FitnessApp
//
//  Barcode → product lookup via the free OpenFoodFacts REST API.
//  Endpoint: https://world.openfoodfacts.org/api/v0/product/{barcode}.json
//

import Foundation

// MARK: - Result model (barcode scan result)

struct ScannedProduct {
    let name:            String
    let caloriesPer100g: Double
    let proteinPer100g:  Double
    let fatPer100g:      Double
    let carbsPer100g:    Double

}

// MARK: - Errors

enum OFFError: LocalizedError {
    case notFound, noNutrition, network(Error), invalid

    var errorDescription: String? {
        switch self {
        case .notFound:       return "Продукт не найден в базе штрихкодов"
        case .noNutrition:    return "Нет данных о КБЖУ для этого продукта"
        case .network(let e): return "Ошибка сети: \(e.localizedDescription)"
        case .invalid:        return "Неверный ответ сервера"
        }
    }
}

// MARK: - Service

final class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private init() {}

    func fetchProduct(barcode: String) async throws -> ScannedProduct {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json")
        else { throw OFFError.invalid }

        var request = URLRequest(url: url)
        request.setValue("FitnessApp/1.0 iOS (almazikbeis@gmail.com)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12

        let data: Data
        do {
            let (d, _) = try await URLSession.shared.data(for: request)
            data = d
        } catch {
            throw OFFError.network(error)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OFFError.invalid
        }
        guard (json["status"] as? Int) == 1,
              let product = json["product"] as? [String: Any]
        else { throw OFFError.notFound }

        guard let nutriments = product["nutriments"] as? [String: Any],
              let kcal = (nutriments["energy-kcal_100g"] as? Double)
                      ?? (nutriments["energy-kcal"] as? Double).map({ $0 / 10 })
        else { throw OFFError.noNutrition }

        let protein = nutriments["proteins_100g"]       as? Double ?? 0
        let fat     = nutriments["fat_100g"]            as? Double ?? 0
        let carbs   = nutriments["carbohydrates_100g"]  as? Double ?? 0

        let ru      = (product["product_name_ru"] as? String)?.nilIfEmpty
        let en      = (product["product_name"]    as? String)?.nilIfEmpty
        let rawName = ru ?? en ?? "Продукт"

        let brandRaw = product["brands"] as? String
        let brand    = brandRaw?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        let name     = brand.map { "\(rawName) (\($0))" } ?? rawName

        return ScannedProduct(
            name:            name,
            caloriesPer100g: kcal,
            proteinPer100g:  protein,
            fatPer100g:      fat,
            carbsPer100g:    carbs
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

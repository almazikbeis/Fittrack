//
//  HealthManager.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//
import HealthKit

class HealthManager {
    static let shared = HealthManager()
    private let healthStore = HKHealthStore()

    // Запрашиваем разрешения на доступ к данным HealthKit
    func requestAuthorization() {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if !success {
                print("Не удалось запросить разрешение: \(error?.localizedDescription ?? "Неизвестная ошибка")")
            }
        }
    }

    // Получаем шаги за последние 30 дней
    func fetchStepsForLast30Days(completion: @escaping ([Double]) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        // Определяем диапазон дат: последние 30 дней
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        // Группируем данные по дням
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )

        query.initialResultsHandler = { _, results, error in
            guard let statsCollection = results else {
                print("Ошибка при получении данных о шагах: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                completion([])
                return
            }

            // Проходимся по статистике и сохраняем данные
            var stepsData: [Double] = []
            statsCollection.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let stepCount = sum.doubleValue(for: HKUnit.count())
                    stepsData.append(stepCount)
                } else {
                    stepsData.append(0) // Если данных нет, добавляем 0
                }
            }

            DispatchQueue.main.async {
                completion(stepsData)
            }
        }

        healthStore.execute(query)
    }
    func fetchCaloriesForLast30Days(completion: @escaping ([Double]) -> Void) {
        guard let calorieType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: calorieType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )

        query.initialResultsHandler = { _, results, error in
            guard let statsCollection = results else {
                print("Ошибка при получении данных о калориях: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                completion([])
                return
            }

            var calorieData: [Double] = []
            statsCollection.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                    calorieData.append(calories)
                } else {
                    calorieData.append(0)
                }
            }

            DispatchQueue.main.async {
                completion(calorieData)
            }
        }

        healthStore.execute(query)
    }

    func fetchDistanceForLast30Days(completion: @escaping ([Double]) -> Void) {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )

        query.initialResultsHandler = { _, results, error in
            guard let statsCollection = results else {
                print("Ошибка при получении данных о дистанции: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                completion([])
                return
            }

            var distanceData: [Double] = []
            statsCollection.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let distance = sum.doubleValue(for: HKUnit.meter()) / 1000.0 // Конвертируем в километры
                    distanceData.append(distance)
                } else {
                    distanceData.append(0)
                }
            }

            DispatchQueue.main.async {
                completion(distanceData)
            }
        }

        healthStore.execute(query)
    }

    func fetchFlightsForLast30Days(completion: @escaping ([Double]) -> Void) {
        guard let flightsType = HKObjectType.quantityType(forIdentifier: .flightsClimbed) else { return }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: flightsType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )

        query.initialResultsHandler = { _, results, error in
            guard let statsCollection = results else {
                print("Ошибка при получении данных о этажах: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                completion([])
                return
            }

            var flightsData: [Double] = []
            statsCollection.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let flights = sum.doubleValue(for: HKUnit.count())
                    flightsData.append(flights)
                } else {
                    flightsData.append(0)
                }
            }

            DispatchQueue.main.async {
                completion(flightsData)
            }
        }

        healthStore.execute(query)
    }


    // Добавьте аналогичные методы для калорий, дистанции и этажей
}

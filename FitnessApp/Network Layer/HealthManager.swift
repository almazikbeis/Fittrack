//
//  HealthManager.swift
//  FitnessApp
//

import HealthKit

class HealthManager {
    static let shared = HealthManager()
    private let healthStore = HKHealthStore()

    func requestAuthorization() {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!
        ]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, _ in }
    }

    // MARK: - Today Stats

    func fetchTodayStats(completion: @escaping (_ steps: Double, _ calories: Double) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        var steps: Double = 0
        var calories: Double = 0
        let group = DispatchGroup()

        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            group.enter()
            let q = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                group.leave()
            }
            healthStore.execute(q)
        }

        if let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            group.enter()
            let q = HKStatisticsQuery(quantityType: calType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                calories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                group.leave()
            }
            healthStore.execute(q)
        }

        group.notify(queue: .main) { completion(steps, calories) }
    }

    // MARK: - 30-Day History

    func fetchStepsForLast30Days(completion: @escaping ([Double]) -> Void) {
        fetch30Days(.stepCount, unit: .count(), completion: completion)
    }

    func fetchCaloriesForLast30Days(completion: @escaping ([Double]) -> Void) {
        fetch30Days(.activeEnergyBurned, unit: .kilocalorie(), completion: completion)
    }

    func fetchDistanceForLast30Days(completion: @escaping ([Double]) -> Void) {
        fetch30Days(.distanceWalkingRunning, unit: .meter(), completion: completion)
    }

    func fetchFlightsForLast30Days(completion: @escaping ([Double]) -> Void) {
        fetch30Days(.flightsClimbed, unit: .count(), completion: completion)
    }

    // MARK: - Generic 30-Day Fetch

    private func fetch30Days(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping ([Double]) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        query.initialResultsHandler = { _, results, _ in
            var data: [Double] = []
            results?.enumerateStatistics(from: startDate, to: now) { stat, _ in
                data.append(stat.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            DispatchQueue.main.async { completion(data) }
        }
        healthStore.execute(query)
    }
}

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

    func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func fetchSteps(completion: @escaping (Double) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        fetchStatistics(for: stepType, unit: HKUnit.count(), completion: completion)
    }

    func fetchCalories(completion: @escaping (Double) -> Void) {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        fetchStatistics(for: calorieType, unit: HKUnit.kilocalorie(), completion: completion)
    }

    func fetchDistance(completion: @escaping (Double) -> Void) {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        fetchStatistics(for: distanceType, unit: HKUnit.meter(), completion: completion)
    }

    private func fetchStatistics(for type: HKQuantityType, unit: HKUnit, completion: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            completion(sum.doubleValue(for: unit))
        }

        healthStore.execute(query)
    }
}

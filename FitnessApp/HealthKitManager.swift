//
//  HealthKitManager.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//


import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var steps: [Double] = []
    @Published var calories: [Double] = []
    @Published var distances: [Double] = []
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        let typesToRead: Set<HKObjectType> = [stepType, calorieType, distanceType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchData()
            } else {
                print("HealthKit Authorization Failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func fetchData() {
        fetchSteps()
        fetchCalories()
        fetchDistances()
    }
    
    private func fetchSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        fetchStatistics(for: stepType) { values in
            DispatchQueue.main.async {
                self.steps = values
            }
        }
    }
    
    private func fetchCalories() {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        fetchStatistics(for: calorieType) { values in
            DispatchQueue.main.async {
                self.calories = values
            }
        }
    }
    
    private func fetchDistances() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        fetchStatistics(for: distanceType) { values in
            DispatchQueue.main.async {
                self.distances = values
            }
        }
    }
    
    private func fetchStatistics(for type: HKQuantityType, completion: @escaping ([Double]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: nil,
            options: [.cumulativeSum],
            anchorDate: calendar.startOfDay(for: now),
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, results, error in
            guard let results = results else {
                print("Error fetching statistics: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            var values: [Double] = []
            results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let value = sum.doubleValue(for: HKUnit.count()) // Adjust units for other types
                    values.append(value)
                } else {
                    values.append(0)
                }
            }
            completion(values)
        }
        
        healthStore.execute(query)
    }
}

//
//  WorkoutRoute.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//


import Foundation
import CoreLocation

struct WorkoutRoute: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double
    let duration: TimeInterval
    let route: [CLLocationCoordinate2D]
    let averageSpeed: Double
}

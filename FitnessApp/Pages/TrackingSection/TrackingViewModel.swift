//
//  TrackingViewModel.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//
import Foundation
import CoreLocation
import MapKit

class TrackingViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Начальные координаты
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var route: [CLLocationCoordinate2D] = [] // Маршрут пользователя
    @Published var distance: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var duration: TimeInterval = 0.0
    @Published var isTracking: Bool = false

    private var locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var startTime: Date?
    private var timer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        isTracking = true
        route = []
        distance = 0.0
        speed = 0.0
        startTime = Date()
        locationManager.startUpdatingLocation()
        startTimer()
    }

    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        stopTimer()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        if isTracking {
            if let lastLocation = lastLocation {
                let distanceIncrement = location.distance(from: lastLocation) // Расстояние в метрах
                distance += distanceIncrement / 1000.0 // Перевод в километры
                speed = location.speed > 0 ? location.speed * 3.6 : 0 // Скорость в км/ч
            }
            route.append(location.coordinate)
            lastLocation = location
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("Доступ к местоположению запрещён.")
        default:
            manager.requestWhenInUseAuthorization()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.duration = Date().timeIntervalSince(self.startTime ?? Date())
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

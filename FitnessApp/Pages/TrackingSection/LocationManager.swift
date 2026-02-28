//
//  LocationManager.swift
//  FitnessApp
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var lastLocation: CLLocation?
    @Published var route: [CLLocation] = []
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []

    private var isTracking = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // обновлять каждые 5 метров
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        route = []
        routeCoordinates = []
        isTracking = true
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        // Фильтруем неточные точки
        guard newLocation.horizontalAccuracy >= 0,
              newLocation.horizontalAccuracy < 50 else { return }

        lastLocation = newLocation

        guard isTracking else { return }
        route.append(newLocation)
        routeCoordinates.append(newLocation.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}

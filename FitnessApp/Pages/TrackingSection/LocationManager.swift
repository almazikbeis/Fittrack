//
//  LocationManager.swift
//  FitnessApp
//

import Foundation
import CoreLocation

struct RunSplit: Identifiable {
    let id = UUID()
    let km: Int
    let pace: Double   // seconds per km
    let elapsed: Int   // total active seconds at this split
}

class LocationManager: NSObject, ObservableObject {
    private let clManager = CLLocationManager()

    @Published var lastLocation: CLLocation?
    @Published var route: [CLLocation] = []
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var currentPace: Double = 0      // sec/km (instantaneous)
    @Published var splits: [RunSplit] = []
    @Published var elevationGain: Double = 0

    private var isRecording = false
    private var totalDistance: Double = 0       // meters (full run)
    private var splitDistance: Double = 0       // meters since last split
    private var splitStartTime: Date?
    private var runStartTime: Date?
    private var lastElevation: Double?

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = 5
    }

    func requestAuthorization() {
        clManager.requestWhenInUseAuthorization()
    }

    // Fresh run — clears everything and starts GPS + recording
    func startTracking() {
        route = []
        routeCoordinates = []
        splits = []
        totalDistance = 0
        splitDistance = 0
        elevationGain = 0
        currentPace = 0
        lastElevation = nil
        runStartTime = Date()
        splitStartTime = Date()
        isRecording = true
        clManager.startUpdatingLocation()
    }

    // Pause — GPS keeps running so user dot stays visible, but route recording stops
    func pauseTracking() {
        isRecording = false
    }

    // Resume — continues recording into the existing route
    func resumeTracking() {
        splitStartTime = Date()   // reset split timer (excludes paused time)
        isRecording = true
    }

    // Stop — halts GPS entirely (called when showing summary or discarding)
    func stopTracking() {
        isRecording = false
        clManager.stopUpdatingLocation()
    }

    // Reset after save/discard — clears route data and restarts passive GPS for user dot
    func resetForNewRun() {
        route = []
        routeCoordinates = []
        splits = []
        totalDistance = 0
        splitDistance = 0
        elevationGain = 0
        currentPace = 0
        lastElevation = nil
        runStartTime = nil
        splitStartTime = nil
        isRecording = false
        clManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        guard newLocation.horizontalAccuracy >= 0,
              newLocation.horizontalAccuracy < 30 else { return }

        lastLocation = newLocation

        guard isRecording else { return }

        // Elevation gain
        if let prevAlt = lastElevation, newLocation.altitude > prevAlt {
            elevationGain += newLocation.altitude - prevAlt
        }
        lastElevation = newLocation.altitude

        // Instantaneous pace from GPS speed
        if newLocation.speed > 0.5 {
            currentPace = 1000.0 / newLocation.speed
        }

        // Distance + per-km splits
        if let prev = route.last {
            let delta = newLocation.distance(from: prev)
            totalDistance += delta
            splitDistance += delta

            if splitDistance >= 1000.0 {
                let splitElapsed = Date().timeIntervalSince(splitStartTime ?? Date())
                let splitPace = splitElapsed / (splitDistance / 1000.0)
                let totalActive = Int(Date().timeIntervalSince(runStartTime ?? Date()))
                splits.append(RunSplit(km: splits.count + 1, pace: splitPace, elapsed: totalActive))
                splitDistance -= 1000.0
                splitStartTime = Date()
            }
        }

        route.append(newLocation)
        routeCoordinates.append(newLocation.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            clManager.startUpdatingLocation()
        }
    }
}

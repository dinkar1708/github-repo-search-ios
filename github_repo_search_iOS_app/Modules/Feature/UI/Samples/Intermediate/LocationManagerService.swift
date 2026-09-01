//
//  LocationManagerService.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/25.
//

import Foundation
import CoreLocation
import Combine

/// High-level tracking modes for location services
enum LocationTrackingMode: String, CaseIterable, Identifiable {
    case idle = "Idle"
    case oneTime = "One-Time (Single Fix)"
    case continuous = "Continuous Foreground"
    case background = "Continuous Background"
    case significantChanges = "Significant Changes"
    case geofencing = "Geofencing / Region"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .idle:
            return "No active location tracking."
        case .oneTime:
            return "Requests a single high-accuracy GPS fix via requestLocation() and stops."
        case .continuous:
            return "Streams real-time updates with standard GPS distance filtering."
        case .background:
            return "Continuous updates in background with allowsBackgroundLocationUpdates enabled."
        case .significantChanges:
            return "Ultra low-power updates based on cellular tower transitions (~500m+)."
        case .geofencing:
            return "Monitors entry/exit boundaries around defined circular geographic regions."
        }
    }
}

/// Structure representing a processed location telemetry point
struct LocationTelemetryPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let horizontalAccuracy: Double
    let speed: Double
    let course: Double
    let isBackground: Bool
    let trackingMode: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        altitude: Double = 0.0,
        horizontalAccuracy: Double = 5.0,
        speed: Double = 0.0,
        course: Double = 0.0,
        isBackground: Bool = false,
        trackingMode: String = "Continuous"
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.course = course
        self.isBackground = isBackground
        self.trackingMode = trackingMode
    }
}

/// Comprehensive Location Manager Service supporting One-Time, Continuous, Background, and Geofencing tracking
@Observable
@MainActor
final class LocationManagerService: NSObject {
    static let shared = LocationManagerService()

    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var isLocationServicesEnabled: Bool = CLLocationManager.locationServicesEnabled()
    private(set) var currentTrackingMode: LocationTrackingMode = .idle
    private(set) var lastLocation: CLLocation?
    private(set) var locationHistory: [LocationTelemetryPoint] = []
    private(set) var recentLogs: [LifecycleLogEntry] = []
    private(set) var monitoredRegions: [CLCircularRegion] = []
    private(set) var insideRegions: Set<String> = []
    private(set) var isSimulating: Bool = false

    private let locationManager = CLLocationManager()
    private var simulationTimer: Timer?
    private var simulatedLatitude: Double = 35.6812 // Tokyo Station coordinates
    private var simulatedLongitude: Double = 139.7671

    override public init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // 10 meters
        locationManager.activityType = .otherNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permission Requests

    func requestWhenInUseAuthorization() {
        addLog("📍 Requesting 'When In Use' Location Authorization")
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        addLog("📍 Requesting 'Always / Background' Location Authorization")
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - 1. One-Time Location Request

    func requestOneTimeLocation() {
        stopAllTracking()
        currentTrackingMode = .oneTime
        addLog("🎯 [One-Time Location] Calling locationManager.requestLocation()")
        print("📍 [LocationSDK] Requesting one-time location fix...")

        if isSimulating {
            simulateSingleFix()
        } else {
            locationManager.requestLocation()
        }
    }

    // MARK: - 2. Continuous Foreground Location

    func startContinuousForegroundTracking() {
        stopAllTracking()
        currentTrackingMode = .continuous
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.showsBackgroundLocationIndicator = false

        addLog("▶️ [Continuous Foreground] Started (distanceFilter: 5m)")
        print("📍 [LocationSDK] Continuous Foreground tracking started.")

        if isSimulating {
            startSimulationTimer(interval: 2.0)
        } else {
            locationManager.startUpdatingLocation()
        }
    }

    // MARK: - 3. Continuous Background Location

    func startContinuousBackgroundTracking() {
        stopAllTracking()
        currentTrackingMode = .background
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        locationManager.pausesLocationUpdatesAutomatically = false

        // Check background capability
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true

        addLog("🌐 [Continuous Background] Started (allowsBackgroundLocationUpdates: true, indicator: true)")
        print("📍 [LocationSDK] Background location updates active. Blue status bar indicator enabled.")

        if isSimulating {
            startSimulationTimer(interval: 3.0)
        } else {
            locationManager.startUpdatingLocation()
        }
    }

    // MARK: - 4. Significant Location Changes (Low Power)

    func startSignificantLocationChanges() {
        stopAllTracking()
        currentTrackingMode = .significantChanges
        addLog("🔋 [Significant Changes] Started ultra-low power cell tower monitoring")
        print("📍 [LocationSDK] Significant Location Change Monitoring started (wake-from-terminated support).")

        if isSimulating {
            startSimulationTimer(interval: 6.0)
        } else {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }

    // MARK: - 5. Geofencing / Region Monitoring

    func startGeofencingDemo() {
        stopAllTracking()
        currentTrackingMode = .geofencing

        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            addLog("⚠️ Region monitoring not supported on this hardware")
            return
        }

        // Create sample circular regions
        let center = lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let region1 = CLCircularRegion(
            center: center,
            radius: 100.0,
            identifier: "Geofence_Hub_Alpha"
        )
        region1.notifyOnEntry = true
        region1.notifyOnExit = true

        let region2 = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: center.latitude + 0.002, longitude: center.longitude + 0.002),
            radius: 150.0,
            identifier: "Geofence_Beacon_Zone_Beta"
        )
        region2.notifyOnEntry = true
        region2.notifyOnExit = true

        monitoredRegions = [region1, region2]

        for region in monitoredRegions {
            locationManager.startMonitoring(for: region)
            addLog("⭕️ [Geofence] Monitoring region: \(region.identifier) (radius: \(Int(region.radius))m)")
        }

        if isSimulating {
            startSimulationTimer(interval: 2.5)
        } else {
            locationManager.startUpdatingLocation()
        }
    }

    // MARK: - Stop & Reset

    func stopAllTracking() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()

        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }

        if currentTrackingMode != .idle {
            addLog("⏹️ Stopped tracking mode: \(currentTrackingMode.rawValue)")
            print("📍 [LocationSDK] Stopped tracking.")
        }
        currentTrackingMode = .idle
    }

    func clearHistory() {
        locationHistory.removeAll()
        recentLogs.removeAll()
        addLog("🧹 Cleared location history and logs")
    }

    func toggleSimulationMode() {
        isSimulating.toggle()
        addLog("🕹️ Simulation mode: \(isSimulating ? "ON" : "OFF")")
        print("📍 [LocationSDK] Simulator mock generator is now \(isSimulating ? "ACTIVE" : "INACTIVE")")
        if isSimulating {
            // Seed initial position
            if lastLocation == nil {
                let initial = CLLocation(latitude: 35.6812, longitude: 139.7671)
                processLocation(initial)
            }
        }
    }

    // MARK: - Simulation Engine (For Simulator & Demos)

    private func simulateSingleFix() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            let fix = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: self.simulatedLatitude, longitude: self.simulatedLongitude),
                altitude: 35.0,
                horizontalAccuracy: 4.2,
                verticalAccuracy: 3.0,
                timestamp: Date()
            )
            self.processLocation(fix)
            self.addLog("✅ [One-Time Fix] Acquired: (\(String(format: "%.5f", fix.coordinate.latitude)), \(String(format: "%.5f", fix.coordinate.longitude))) accuracy: \(String(format: "%.1f", fix.horizontalAccuracy))m")
            self.currentTrackingMode = .idle
        }
    }

    private func startSimulationTimer(interval: TimeInterval) {
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Simulate pedestrian movement with slight drift
                let deltaLat = (Double.random(in: -0.0003...0.0003))
                let deltaLon = (Double.random(in: -0.0003...0.0003))
                self.simulatedLatitude += deltaLat
                self.simulatedLongitude += deltaLon

                let simulatedSpeed = Double.random(in: 1.1...1.5) // ~4-5 km/h pedestrian walk
                let simulatedCourse = Double.random(in: 0...360)
                let location = CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: self.simulatedLatitude, longitude: self.simulatedLongitude),
                    altitude: 35.0,
                    horizontalAccuracy: Double.random(in: 3.0...8.5),
                    verticalAccuracy: 4.0,
                    course: simulatedCourse,
                    speed: simulatedSpeed,
                    timestamp: Date()
                )

                self.processLocation(location)

                // Simulate geofence checks
                for region in self.monitoredRegions {
                    let distance = location.distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
                    let wasInside = self.insideRegions.contains(region.identifier)
                    let isInside = distance <= region.radius

                    if isInside && !wasInside {
                        self.insideRegions.insert(region.identifier)
                        self.addLog("🚪 [Geofence Enter] Entered: \(region.identifier) (dist: \(Int(distance))m)")
                        print("📍 [GeofenceSDK] ENTERED: \(region.identifier)")
                    } else if !isInside && wasInside {
                        self.insideRegions.remove(region.identifier)
                        self.addLog("🚪 [Geofence Exit] Exited: \(region.identifier) (dist: \(Int(distance))m)")
                        print("📍 [GeofenceSDK] EXITED: \(region.identifier)")
                    }
                }
            }
        }
    }

    private func processLocation(_ location: CLLocation) {
        lastLocation = location
        let point = LocationTelemetryPoint(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            speed: max(0, location.speed),
            course: max(0, location.course),
            isBackground: currentTrackingMode == .background,
            trackingMode: currentTrackingMode.rawValue
        )

        locationHistory.insert(point, at: 0)
        if locationHistory.count > 100 {
            locationHistory.removeLast()
        }

        let speedStr = location.speed > 0 ? String(format: "%.1f m/s", location.speed) : "stationary"
        let logMsg = "📍 [\(currentTrackingMode.rawValue)] Lat: \(String(format: "%.5f", location.coordinate.latitude)), Lon: \(String(format: "%.5f", location.coordinate.longitude)), Acc: ±\(String(format: "%.1f", location.horizontalAccuracy))m (\(speedStr))"
        addLog(logMsg)
        print("📍 [LocationSDK] \(logMsg)")
    }

    private func addLog(_ message: String) {
        let entry = LifecycleLogEntry(timestamp: Date(), message: message)
        recentLogs.insert(entry, at: 0)
        if recentLogs.count > 60 {
            recentLogs.removeLast()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManagerService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            self.addLog("🔐 Authorization Status Changed: \(self.statusDescription(manager.authorizationStatus))")
            print("📍 [LocationSDK] Authorization: \(self.statusDescription(manager.authorizationStatus))")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.processLocation(latest)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.addLog("❌ Location Error: \(error.localizedDescription)")
            print("❌ [LocationSDK] Location manager failed with error: \(error.localizedDescription)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            self.insideRegions.insert(region.identifier)
            self.addLog("🚪 [Geofence Enter] Entered: \(region.identifier)")
            print("📍 [GeofenceSDK] Delegate Entered: \(region.identifier)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            self.insideRegions.remove(region.identifier)
            self.addLog("🚪 [Geofence Exit] Exited: \(region.identifier)")
            print("📍 [GeofenceSDK] Delegate Exited: \(region.identifier)")
        }
    }

    private func statusDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always (Background OK)"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
}

# iOS Location Services Guide: One-Time, Continuous & Background Tracking

A production-grade guide covering **CoreLocation** tracking modes, authorization flows, battery optimization strategies, and background location processing.

---

## 1. Tracking Modes Overview

| Mode | API | Accuracy | Battery Impact | Primary Use Cases |
| :--- | :--- | :--- | :--- | :--- |
| **One-Time Fix** | `requestLocation()` | High (< 5m) | Single burst (~0.5s) | Weather, geo-tagging, check-ins, initial seed |
| **Continuous (Foreground)** | `startUpdatingLocation()` | High (< 5m) | Moderate (active GPS) | Turn-by-turn navigation, fitness tracking |
| **Continuous (Background)** | `allowsBackgroundLocationUpdates = true` | High (< 5m) | High (sustained GPS) | Fleet management, delivery tracking |
| **Significant Location Changes** | `startMonitoringSignificantLocationChanges()` | ~500m+ (Cell/Wi-Fi) | Ultra Low (<0.5%/day) | Commute logs, background wake from terminated state |
| **Geofencing / Region** | `startMonitoring(for: CLCircularRegion)` | 50m - 150m | Low (~1%/day) | Store entry/exit, location-based reminders |

---

## 2. Authorization Flow & Permissions

iOS enforces a two-tier authorization model:

```text
[ Not Determined ]
       │
       ▼ (requestWhenInUseAuthorization)
[ When In Use ]
       │
       ▼ (requestAlwaysAuthorization)
[ Always (Background) ]
```

### Required `Info.plist` Privacy Keys

```xml
<!-- Foreground GPS Access -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location for real-time tracking.</string>

<!-- Background GPS Access (iOS 11+) -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need background location for telemetry collection.</string>

<!-- Background Modes Capability -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

---

## 3. One-Time Location Fix (`requestLocation`)

When you only need a single coordinate snapshot (e.g. searching nearby restaurants), use `requestLocation()` instead of starting and stopping continuous updates manually.

### Why `requestLocation()` is Better:
1. Automatically turns off GPS hardware immediately after receiving the first high-accuracy fix.
2. Automatically times out and calls `locationManager(_:didFailWithError:)` if no GPS fix is acquired within reasonable time.
3. Conserves device battery compared to manual `startUpdatingLocation()` / `stopUpdatingLocation()`.

```swift
func requestOneTimeLocation() {
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestLocation()
}

// Delegate Callback
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    print("🎯 One-time coordinate: \(location.coordinate.latitude), \(location.coordinate.longitude)")
}
```

---

## 4. Continuous Background Location

To keep receiving location updates when the app transitions to the background:

```swift
func startContinuousBackgroundTracking() {
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 10.0 // meters
    locationManager.activityType = .otherNavigation
    
    // Background tracking requirements
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.showsBackgroundLocationIndicator = true // Blue pill in status bar
    
    locationManager.startUpdatingLocation()
}
```

> [!IMPORTANT]
> Always set `showsBackgroundLocationIndicator = true` on iOS 11+ to inform the user that background location is active. If `allowsBackgroundLocationUpdates` is set to `true` without adding `location` to `UIBackgroundModes`, the app will crash with an assertion failure at runtime.

---

## 5. Significant Location Changes (Low Power Background Wake)

Significant Location Change monitoring uses cellular tower handoffs and Wi-Fi networks instead of powering the GPS chip.

### Key Advantages:
• **Wakes App from Terminated State:** If the user or OS kills the app, iOS will relaunch the app in the background (`UIApplication.LaunchOptionsKey.location`) when a significant move occurs (~500m+).
• **Negligible Battery Consumption:** Consumes almost zero additional battery since cell tower scanning is already performed by the baseband processor.

```swift
func startSignificantLocationMonitoring() {
    guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
    locationManager.startMonitoringSignificantLocationChanges()
}
```

---

## 6. Geofencing (Circular Region Monitoring)

```swift
func monitorGeofence(center: CLLocationCoordinate2D, radiusMeters: Double, identifier: String) {
    guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
    
    let region = CLCircularRegion(center: center, radius: radiusMeters, identifier: identifier)
    region.notifyOnEntry = true
    region.notifyOnExit = true
    
    locationManager.startMonitoring(for: region)
}

// Delegate Callbacks
func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    print("🚪 Entered boundary: \(region.identifier)")
}

func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    print("🚪 Exited boundary: \(region.identifier)")
}
```

---

## 7. Interactive Sample in Project

Try the live interactive sample in the app:
• **Source View:** `LocationTrackingSampleView.swift`
• **Core Service:** `LocationManagerService.swift`
• **Hub Navigation:** *Samples → Intermediate → Location Tracking (One-Time & Background)*

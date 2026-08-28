//
//  LocationTrackingSampleView.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/25.
//

import SwiftUI
import CoreLocation

/// Interactive Sample View demonstrating One-Time, Continuous, Background Location, and Geofencing tracking
public struct LocationTrackingSampleView: View {
    @StateObject private var locationService = LocationManagerService.shared
    @StateObject private var pipelineQueue = LocationDataPipelineQueue.shared
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Banner
                LocationHeaderCard(
                    authStatus: locationService.authorizationStatus,
                    currentMode: locationService.currentTrackingMode,
                    isSimulating: locationService.isSimulating,
                    onToggleSimulation: {
                        locationService.toggleSimulationMode()
                    }
                )

                // Mode Selector Control Card
                TrackingModeSelectorCard(
                    currentMode: locationService.currentTrackingMode,
                    onRequestWhenInUse: { locationService.requestWhenInUseAuthorization() },
                    onRequestAlways: { locationService.requestAlwaysAuthorization() },
                    onSelectOneTime: { locationService.requestOneTimeLocation() },
                    onSelectContinuous: { locationService.startContinuousForegroundTracking() },
                    onSelectBackground: { locationService.startContinuousBackgroundTracking() },
                    onSelectSignificant: { locationService.startSignificantLocationChanges() },
                    onSelectGeofence: { locationService.startGeofencingDemo() },
                    onStop: { locationService.stopAllTracking() }
                )

                // Current Coordinate & Telemetry Card
                if let loc = locationService.lastLocation {
                    CurrentLocationTelemetryCard(location: loc, mode: locationService.currentTrackingMode)
                }

                // Geofence Region Status Card (if geofencing active)
                if locationService.currentTrackingMode == .geofencing {
                    GeofenceStatusCard(
                        regions: locationService.monitoredRegions,
                        insideRegions: locationService.insideRegions
                    )
                }

                // Recent Location Telemetry Stream (Last 5 Points)
                if !locationService.locationHistory.isEmpty {
                    LocationHistoryCard(points: Array(locationService.locationHistory.prefix(5)))
                }

                // Live Event Log Card
                LifecycleEventLogCard(
                    logs: locationService.recentLogs,
                    onClear: { locationService.clearHistory() }
                )
            }
            .padding()
        }
        .navigationTitle("Location Services")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("📍 [LocationSample] LocationTrackingSampleView appeared.")
        }
        .onDisappear {
            // Keep background running if user selected background mode, otherwise stop simulation
        }
    }
}

// MARK: - Subcomponents

struct LocationHeaderCard: View {
    let authStatus: CLAuthorizationStatus
    let currentMode: LocationTrackingMode
    let isSimulating: Bool
    let onToggleSimulation: () -> Void

    var statusColor: Color {
        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse: return .green
        case .denied, .restricted: return .red
        default: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CoreLocation Tracking Engine")
                        .font(.headline)
                    Text("One-Time, Continuous, Background & Geofencing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onToggleSimulation) {
                    HStack(spacing: 4) {
                        Image(systemName: isSimulating ? "play.circle.fill" : "pause.circle")
                        Text(isSimulating ? "Sim ON" : "Sim OFF")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isSimulating ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundColor(isSimulating ? .green : .secondary)
                    .cornerRadius(8)
                }
            }

            Divider()

            HStack {
                Label("Auth: \(authDescription(authStatus))", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundColor(statusColor)

                Spacer()

                Label("Mode: \(currentMode.rawValue)", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundColor(currentMode == .idle ? .secondary : .blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func authDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return "Always (Background OK)"
        case .authorizedWhenInUse: return "When In Use"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }
}

struct TrackingModeSelectorCard: View {
    let currentMode: LocationTrackingMode
    let onRequestWhenInUse: () -> Void
    let onRequestAlways: () -> Void
    let onSelectOneTime: () -> Void
    let onSelectContinuous: () -> Void
    let onSelectBackground: () -> Void
    let onSelectSignificant: () -> Void
    let onSelectGeofence: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tracking Mode Actions")
                .font(.headline)

            // Permissions row
            HStack(spacing: 8) {
                Button("Req WhenInUse") {
                    onRequestWhenInUse()
                }
                .font(.caption)
                .buttonStyle(.bordered)

                Button("Req Always (BG)") {
                    onRequestAlways()
                }
                .font(.caption)
                .buttonStyle(.bordered)

                Spacer()

                Button("Stop All") {
                    onStop()
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

            Divider()

            // Modes Grid
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ModeButton(
                        title: "🎯 One-Time Fix",
                        subtitle: "Single high-accuracy GPS fix",
                        isActive: currentMode == .oneTime,
                        action: onSelectOneTime
                    )

                    ModeButton(
                        title: "▶️ Continuous",
                        subtitle: "Foreground GPS stream",
                        isActive: currentMode == .continuous,
                        action: onSelectContinuous
                    )
                }

                HStack(spacing: 8) {
                    ModeButton(
                        title: "🌐 Background",
                        subtitle: "allowsBackgroundLocationUpdates",
                        isActive: currentMode == .background,
                        action: onSelectBackground
                    )

                    ModeButton(
                        title: "🔋 Significant",
                        subtitle: "Low-power cell tower changes",
                        isActive: currentMode == .significantChanges,
                        action: onSelectSignificant
                    )
                }

                ModeButton(
                    title: "⭕️ Geofencing Demo",
                    subtitle: "CLCircularRegion entry/exit boundaries (100m - 150m)",
                    isActive: currentMode == .geofencing,
                    action: onSelectGeofence
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ModeButton: View {
    let title: String
    let subtitle: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .white : .primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(isActive ? Color.white.opacity(0.85) : .secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(isActive ? Color.blue : Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct CurrentLocationTelemetryCard: View {
    let location: CLLocation
    let mode: LocationTrackingMode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundColor(.green)
                Text("Live Telemetry Coordinates")
                    .font(.headline)
                Spacer()
                Text(location.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricItem(label: "Latitude", value: String(format: "%.6f°", location.coordinate.latitude))
                MetricItem(label: "Longitude", value: String(format: "%.6f°", location.coordinate.longitude))
                MetricItem(label: "Accuracy", value: "±\(String(format: "%.1f", location.horizontalAccuracy)) m")
                MetricItem(label: "Altitude", value: "\(String(format: "%.1f", location.altitude)) m")
                MetricItem(label: "Speed", value: location.speed >= 0 ? String(format: "%.1f m/s", location.speed) : "Stationary")
                MetricItem(label: "Course", value: location.course >= 0 ? String(format: "%.0f°", location.course) : "N/A")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MetricItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(6)
    }
}

struct GeofenceStatusCard: View {
    let regions: [CLCircularRegion]
    let insideRegions: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Geofenced Regions (\(regions.count))")
                .font(.headline)

            ForEach(regions, id: \.identifier) { region in
                let isInside = insideRegions.contains(region.identifier)
                HStack {
                    Image(systemName: isInside ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundColor(isInside ? .green : .orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(region.identifier)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Radius: \(Int(region.radius))m | (\(String(format: "%.4f", region.center.latitude)), \(String(format: "%.4f", region.center.longitude)))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(isInside ? "INSIDE" : "OUTSIDE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isInside ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                        .foregroundColor(isInside ? .green : .secondary)
                        .cornerRadius(4)
                }
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct LocationHistoryCard: View {
    let points: [LocationTelemetryPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Telemetry Buffer Stream")
                .font(.headline)

            ForEach(points) { pt in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("(\(String(format: "%.5f", pt.latitude)), \(String(format: "%.5f", pt.longitude)))")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(pt.trackingMode) | Acc: ±\(String(format: "%.1f", pt.horizontalAccuracy))m | \(pt.isBackground ? "BG" : "FG")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(pt.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(6)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

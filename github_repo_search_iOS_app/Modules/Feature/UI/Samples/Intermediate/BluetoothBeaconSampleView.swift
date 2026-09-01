//
//  BluetoothBeaconSampleView.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/25.
//

import SwiftUI
import CoreBluetooth
import CoreLocation

/// Interactive Sample View for BLE Peripheral Scanning, RSSI monitoring, and iBeacon ranging
public struct BluetoothBeaconSampleView: View {
    @State private var bluetoothService = BluetoothBeaconService.shared
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Status Card
                BluetoothHeaderCard(
                    btState: bluetoothService.bluetoothState,
                    isScanningBLE: bluetoothService.isScanningBLE,
                    isRangingBeacons: bluetoothService.isRangingBeacons,
                    isSimulating: bluetoothService.isSimulating,
                    onToggleSimulation: {
                        bluetoothService.toggleSimulationMode()
                    }
                )

                // Actions Control Card
                BluetoothActionsCard(
                    isScanningBLE: bluetoothService.isScanningBLE,
                    isRangingBeacons: bluetoothService.isRangingBeacons,
                    onStartBLE: { bluetoothService.startBLEScanning() },
                    onStopBLE: { bluetoothService.stopBLEScanning() },
                    onStartBeacon: { bluetoothService.startBeaconRanging() },
                    onStopBeacon: { bluetoothService.stopBeaconRanging() }
                )

                // Segmented Picker for Peripherals vs. Beacons
                Picker("Scan Mode", selection: $selectedTab) {
                    Text("iBeacons (\(bluetoothService.discoveredBeacons.count))").tag(0)
                    Text("BLE Peripherals (\(bluetoothService.discoveredPeripherals.count))").tag(1)
                }
                .pickerStyle(.segmented)

                if selectedTab == 0 {
                    // iBeacon Ranging Radar Card
                    BeaconRangingListCard(
                        beacons: bluetoothService.discoveredBeacons,
                        targetUUID: bluetoothService.targetBeaconUUID
                    )
                } else {
                    // Discovered BLE Peripherals Card
                    PeripheralListCard(peripherals: bluetoothService.discoveredPeripherals)
                }

                // Live Event Log Card
                LifecycleEventLogCard(
                    logs: bluetoothService.recentLogs,
                    onClear: { bluetoothService.clearDiscoveredDevices() }
                )
            }
            .padding()
        }
        .navigationTitle("Bluetooth & Beacons")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🔵 [BluetoothSample] BluetoothBeaconSampleView appeared.")
        }
    }
}

// MARK: - Subcomponents

struct BluetoothHeaderCard: View {
    let btState: CBManagerState
    let isScanningBLE: Bool
    let isRangingBeacons: Bool
    let isSimulating: Bool
    let onToggleSimulation: () -> Void

    var stateColor: Color {
        switch btState {
        case .poweredOn: return .green
        case .poweredOff, .unauthorized, .unsupported: return .red
        default: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CoreBluetooth & Beacon Scanner")
                        .font(.headline)
                    Text("BLE Advertisements, RSSI & iBeacon Proximity")
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
                Label("Status: \(stateDescription(btState))", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(stateColor)

                Spacer()

                if isScanningBLE || isRangingBeacons {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Active Scanning")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("Idle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func stateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOn: return "Powered On (Ready)"
        case .poweredOff: return "Powered Off"
        case .unauthorized: return "Unauthorized"
        case .unsupported: return "Unsupported"
        case .resetting: return "Resetting"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

struct BluetoothActionsCard: View {
    let isScanningBLE: Bool
    let isRangingBeacons: Bool
    let onStartBLE: () -> Void
    let onStopBLE: () -> Void
    let onStartBeacon: () -> Void
    let onStopBeacon: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scanner Controls")
                .font(.headline)

            HStack(spacing: 10) {
                Button(action: {
                    if isScanningBLE { onStopBLE() } else { onStartBLE() }
                }) {
                    HStack {
                        Image(systemName: isScanningBLE ? "stop.fill" : "dot.radiowaves.forward")
                        Text(isScanningBLE ? "Stop BLE Scan" : "Scan BLE Devices")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(isScanningBLE ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button(action: {
                    if isRangingBeacons { onStopBeacon() } else { onStartBeacon() }
                }) {
                    HStack {
                        Image(systemName: isRangingBeacons ? "stop.fill" : "target")
                        Text(isRangingBeacons ? "Stop Beacons" : "Range iBeacons")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(isRangingBeacons ? Color.red : Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BeaconRangingListCard: View {
    let beacons: [DiscoveredBeacon]
    let targetUUID: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Target Beacon UUID:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(targetUUID.uuidString)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(6)

            if beacons.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No iBeacons Ranged Yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Tap 'Range iBeacons' or toggle 'Sim ON' to simulate nearby beacons.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(beacons) { beacon in
                    HStack(spacing: 12) {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                            .font(.title2)
                            .foregroundColor(.indigo)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("Major: \(beacon.major)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Minor: \(beacon.minor)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text(beacon.proximityDescription)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f m", max(0, beacon.accuracy)))
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("\(beacon.rssi) dBm")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct PeripheralListCard: View {
    let peripherals: [DiscoveredPeripheral]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Discovered BLE Peripherals (\(peripherals.count))")
                .font(.headline)

            if peripherals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No BLE Peripherals Found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Tap 'Scan BLE Devices' or toggle 'Sim ON'.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(peripherals) { p in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(p.name)
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Spacer()
                            Text(p.signalStrengthDescription)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }

                        if !p.serviceUUIDs.isEmpty {
                            HStack(spacing: 4) {
                                Text("Services:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                ForEach(p.serviceUUIDs.prefix(3), id: \.self) { svc in
                                    Text(svc)
                                        .font(.system(.caption2, design: .monospaced))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }

                        if let mfg = p.manufacturerDataHex {
                            Text("Mfg Data: \(mfg.prefix(16))...")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Est. Distance: ~\(String(format: "%.1f", p.estimatedDistanceMeters))m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(p.lastSeen, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

//
//  BluetoothBeaconService.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/25.
//

import Foundation
import CoreBluetooth
import CoreLocation
import Combine

/// Discovered BLE Peripheral Model
struct DiscoveredPeripheral: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let serviceUUIDs: [String]
    let manufacturerDataHex: String?
    let txPowerLevel: Int?
    let lastSeen: Date

    var estimatedDistanceMeters: Double {
        // Log-distance path loss formula: d = 10 ^ ((TxPower - RSSI) / (10 * n))
        let tx = txPowerLevel ?? -59
        let n: Double = 2.5 // Environmental attenuation factor
        let ratio = Double(tx - rssi) / (10.0 * n)
        return pow(10.0, ratio)
    }

    var signalStrengthDescription: String {
        switch rssi {
        case -60...0: return "🟢 Excellent (\(rssi) dBm)"
        case -75 ..< -60: return "🟡 Good (\(rssi) dBm)"
        case -90 ..< -75: return "🟠 Fair (\(rssi) dBm)"
        default: return "🔴 Weak (\(rssi) dBm)"
        }
    }
}

/// Discovered iBeacon Model
struct DiscoveredBeacon: Identifiable {
    let id: UUID
    let uuid: UUID
    let major: CLBeaconMajorValue
    let minor: CLBeaconMinorValue
    let proximity: CLProximity
    let accuracy: CLLocationAccuracy
    let rssi: Int
    let timestamp: Date

    var proximityDescription: String {
        switch proximity {
        case .immediate: return "🔥 Immediate (< 0.5m)"
        case .near: return "📍 Near (0.5m - 3.0m)"
        case .far: return "📡 Far (> 3.0m)"
        case .unknown: return "❓ Unknown"
        @unknown default: return "Unknown"
        }
    }
}

/// Comprehensive Bluetooth Low Energy (BLE) & iBeacon Scanner Service
@Observable
@MainActor
final class BluetoothBeaconService: NSObject {
    static let shared = BluetoothBeaconService()

    private(set) var bluetoothState: CBManagerState = .unknown
    private(set) var isScanningBLE: Bool = false
    private(set) var isRangingBeacons: Bool = false
    private(set) var discoveredPeripherals: [DiscoveredPeripheral] = []
    private(set) var discoveredBeacons: [DiscoveredBeacon] = []
    private(set) var recentLogs: [LifecycleLogEntry] = []
    private(set) var isSimulating: Bool = false

    private var centralManager: CBCentralManager?
    private var locationManager: CLLocationManager?
    private var beaconRegion: CLBeaconRegion?
    private var beaconIdentityConstraint: CLBeaconIdentityConstraint?
    private var simulationTimer: Timer?

    // Default Target iBeacon UUID for testing / standard proximity
    let targetBeaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!

    override init() {
        super.init()
        setupServices()
    }

    private func setupServices() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }

    // MARK: - 1. CoreBluetooth BLE Scanning

    func startBLEScanning() {
        guard let central = centralManager else { return }
        guard central.state == .poweredOn else {
            addLog("⚠️ Cannot start BLE scan: Bluetooth state is \(stateDescription(central.state))")
            return
        }

        isScanningBLE = true
        addLog("📡 [BLE Scan] Started scanning for nearby peripherals with duplicate keys allowed")
        print("🔵 [BluetoothSDK] Central manager scanning started.")

        if isSimulating {
            startSimulationTimer()
        } else {
            central.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        }
    }

    func stopBLEScanning() {
        centralManager?.stopScan()
        isScanningBLE = false
        addLog("⏹️ [BLE Scan] Stopped peripheral scanning")
        print("🔵 [BluetoothSDK] Central manager scan stopped.")
    }

    // MARK: - 2. iBeacon Monitoring & Ranging

    func startBeaconRanging() {
        guard let locationManager = locationManager else { return }
        locationManager.requestWhenInUseAuthorization()

        let constraint = CLBeaconIdentityConstraint(uuid: targetBeaconUUID)
        let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "Beacon_Target_Zone")
        region.notifyEntryStateOnDisplay = true
        region.notifyOnEntry = true
        region.notifyOnExit = true

        self.beaconRegion = region
        self.beaconIdentityConstraint = constraint

        isRangingBeacons = true
        locationManager.startMonitoring(for: region)
        locationManager.startRangingBeacons(satisfying: constraint)

        addLog("📶 [iBeacon] Started ranging for UUID: \(targetBeaconUUID.uuidString)")
        print("🔵 [BeaconSDK] Started iBeacon ranging for UUID: \(targetBeaconUUID.uuidString)")

        if isSimulating {
            startSimulationTimer()
        }
    }

    func stopBeaconRanging() {
        guard let locationManager = locationManager else { return }
        if let constraint = beaconIdentityConstraint {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
        if let region = beaconRegion {
            locationManager.stopMonitoring(for: region)
        }
        isRangingBeacons = false
        addLog("⏹️ [iBeacon] Stopped beacon ranging")
        print("🔵 [BeaconSDK] Stopped iBeacon ranging.")
    }

    // MARK: - Simulation Mode (For Simulator testing)

    func toggleSimulationMode() {
        isSimulating.toggle()
        addLog("🕹️ Bluetooth simulation mode: \(isSimulating ? "ON" : "OFF")")
        print("🔵 [BluetoothSDK] Simulation mode is now \(isSimulating ? "ACTIVE" : "INACTIVE")")
        if isSimulating {
            seedSimulatedDevices()
            startSimulationTimer()
        } else {
            simulationTimer?.invalidate()
            simulationTimer = nil
        }
    }

    func clearDiscoveredDevices() {
        discoveredPeripherals.removeAll()
        discoveredBeacons.removeAll()
        recentLogs.removeAll()
        addLog("🧹 Cleared discovered devices and logs")
    }

    private func seedSimulatedDevices() {
        let p1 = DiscoveredPeripheral(
            id: UUID(),
            name: "Smart_Badge_Beacon_01",
            rssi: -58,
            serviceUUIDs: ["180A", "FEAA", "180F"],
            manufacturerDataHex: "4C000215E2C56DB5",
            txPowerLevel: -59,
            lastSeen: Date()
        )
        let p2 = DiscoveredPeripheral(
            id: UUID(),
            name: "Asset_Tag_Pallet_88",
            rssi: -72,
            serviceUUIDs: ["180F"],
            manufacturerDataHex: "4C000215B9407F30",
            txPowerLevel: -59,
            lastSeen: Date()
        )
        let p3 = DiscoveredPeripheral(
            id: UUID(),
            name: "Gateway_Router_Kanda",
            rssi: -45,
            serviceUUIDs: ["FEAA", "1800"],
            manufacturerDataHex: "004C01000000",
            txPowerLevel: -50,
            lastSeen: Date()
        )
        discoveredPeripherals = [p1, p2, p3]

        let b1 = DiscoveredBeacon(
            id: UUID(),
            uuid: targetBeaconUUID,
            major: 101,
            minor: 201,
            proximity: .immediate,
            accuracy: 0.35,
            rssi: -48,
            timestamp: Date()
        )
        let b2 = DiscoveredBeacon(
            id: UUID(),
            uuid: targetBeaconUUID,
            major: 101,
            minor: 202,
            proximity: .near,
            accuracy: 1.82,
            rssi: -67,
            timestamp: Date()
        )
        discoveredBeacons = [b1, b2]

        addLog("🌱 Seeded mock BLE peripherals and iBeacons for simulator")
    }

    private func startSimulationTimer() {
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isSimulating else { return }

                // Jitter RSSI values to simulate real RF signal fluctuations
                self.discoveredPeripherals = self.discoveredPeripherals.map { p in
                    let delta = Int.random(in: -4...4)
                    let newRSSI = min(-30, max(-95, p.rssi + delta))
                    return DiscoveredPeripheral(
                        id: p.id,
                        name: p.name,
                        rssi: newRSSI,
                        serviceUUIDs: p.serviceUUIDs,
                        manufacturerDataHex: p.manufacturerDataHex,
                        txPowerLevel: p.txPowerLevel,
                        lastSeen: Date()
                    )
                }

                // Jitter Beacon accuracy & proximity
                self.discoveredBeacons = self.discoveredBeacons.map { b in
                    let deltaAcc = Double.random(in: -0.15...0.15)
                    let newAcc = max(0.2, b.accuracy + deltaAcc)
                    let newProximity: CLProximity = newAcc < 0.5 ? .immediate : (newAcc < 3.0 ? .near : .far)
                    let deltaRSSI = Int.random(in: -3...3)
                    return DiscoveredBeacon(
                        id: b.id,
                        uuid: b.uuid,
                        major: b.major,
                        minor: b.minor,
                        proximity: newProximity,
                        accuracy: newAcc,
                        rssi: min(-35, max(-90, b.rssi + deltaRSSI)),
                        timestamp: Date()
                    )
                }

                if let first = self.discoveredBeacons.first {
                    let log = "📶 [Beacon Ping] Major: \(first.major), Minor: \(first.minor), RSSI: \(first.rssi) dBm (Acc: \(String(format: "%.2f", first.accuracy))m, \(first.proximityDescription))"
                    self.addLog(log)
                    print("🔵 [BeaconSDK] \(log)")
                }
            }
        }
    }

    private func addLog(_ message: String) {
        let entry = LifecycleLogEntry(timestamp: Date(), message: message)
        recentLogs.insert(entry, at: 0)
        if recentLogs.count > 60 {
            recentLogs.removeLast()
        }
    }

    private func stateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported (No BLE)"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On (Ready)"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothBeaconService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.bluetoothState = central.state
            self.addLog("📶 Central State Updated: \(self.stateDescription(central.state))")
            print("🔵 [BluetoothSDK] Bluetooth State: \(self.stateDescription(central.state))")
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "Unknown Peripheral (\(peripheral.identifier.uuidString.prefix(6)))"
            let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map { $0.uuidString } ?? []
            let txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int

            var mfgHex: String? = nil
            if let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                mfgHex = mfgData.map { String(format: "%02hhX", $0) }.joined()
            }

            let discovered = DiscoveredPeripheral(
                id: peripheral.identifier,
                name: name,
                rssi: RSSI.intValue,
                serviceUUIDs: services,
                manufacturerDataHex: mfgHex,
                txPowerLevel: txPower,
                lastSeen: Date()
            )

            if let idx = self.discoveredPeripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
                self.discoveredPeripherals[idx] = discovered
            } else {
                self.discoveredPeripherals.append(discovered)
                self.addLog("📡 [Discovered BLE] \(name) (RSSI: \(RSSI.intValue) dBm)")
                print("🔵 [BluetoothSDK] Discovered: \(name) [\(RSSI.intValue) dBm]")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate (iBeacon Ranging)

extension BluetoothBeaconService: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying beaconConstraint: CLBeaconIdentityConstraint
    ) {
        Task { @MainActor in
            guard !beacons.isEmpty else { return }

            for beacon in beacons {
                let discovered = DiscoveredBeacon(
                    id: UUID(),
                    uuid: beacon.uuid,
                    major: beacon.major.uint16Value,
                    minor: beacon.minor.uint16Value,
                    proximity: beacon.proximity,
                    accuracy: beacon.accuracy,
                    rssi: beacon.rssi,
                    timestamp: beacon.timestamp
                )

                if let idx = self.discoveredBeacons.firstIndex(where: { $0.major == discovered.major && $0.minor == discovered.minor }) {
                    self.discoveredBeacons[idx] = discovered
                } else {
                    self.discoveredBeacons.append(discovered)
                    self.addLog("🎯 [New Beacon] Major: \(discovered.major), Minor: \(discovered.minor) (\(discovered.proximityDescription))")
                    print("🔵 [BeaconSDK] Ranged New Beacon Major: \(discovered.major), Minor: \(discovered.minor)")
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        Task { @MainActor in
            self.addLog("❌ Beacon Ranging Error: \(error.localizedDescription)")
            print("❌ [BeaconSDK] Ranging failed: \(error.localizedDescription)")
        }
    }
}

# iOS Bluetooth (BLE) & iBeacon Engineering Guide

A comprehensive architectural guide covering **CoreBluetooth** peripheral scanning, RSSI signal estimation, **iBeacon** ranging and monitoring, and background execution.

---

## 1. Bluetooth Low Energy (BLE) vs. iBeacon Architecture

| Characteristic | CoreBluetooth (Generic BLE) | CoreLocation (iBeacon) |
| :--- | :--- | :--- |
| **Framework** | `CoreBluetooth.framework` | `CoreLocation.framework` |
| **Primary Class** | `CBCentralManager`, `CBPeripheral` | `CLLocationManager`, `CLBeaconRegion` |
| **Identifiers** | Service UUIDs (`CBUUID`), Peripheral UUIDs | Proximity UUID, Major (16-bit), Minor (16-bit) |
| **Measurement** | Raw RSSI in dBm (`-30` to `-100 dBm`) | Proximity (`immediate`, `near`, `far`, `unknown`) + accuracy (m) |
| **Background Wake** | State restoration (`bluetooth-central`) | Hardware geofence wake via `CLBeaconRegion` |

---

## 2. CoreBluetooth Central Manager Implementation

### Scanning for Peripherals with Duplicate Keys

```swift
final class BLEScanner: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    
    func startScan() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        
        // Scan for all peripherals or filter by specific Service UUIDs
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "Unknown"
        print("📡 Discovered: \(name), RSSI: \(RSSI) dBm")
    }
}
```

---

## 3. Estimating Distance from RSSI (Path Loss Formula)

Raw RSSI (Received Signal Strength Indicator) fluctuates due to multipath reflection and RF interference. To approximate distance in meters:

$$\text{Distance} = 10^{\frac{\text{TxPower} - \text{RSSI}}{10 \times n}}$$

Where:
• **`TxPower`**: Measured signal strength at 1 meter (typically `-59 dBm`).
• **`RSSI`**: Measured signal strength in dBm.
• **`n`**: Path loss exponent ($2.0$ for open space, $2.5 - 3.5$ for indoor office environments).

```swift
func estimateDistance(rssi: Int, txPower: Int = -59, pathLossExponent: Double = 2.5) -> Double {
    let ratio = Double(txPower - rssi) / (10.0 * pathLossExponent)
    return pow(10.0, ratio)
}
```

---

## 4. iBeacon Ranging & Monitoring (`CoreLocation`)

An iBeacon broadcasts 3 key identifying values:
1. **UUID (128-bit):** Identifies the organization/ecosystem (e.g. all retail stores).
2. **Major (16-bit):** Identifies a specific location or store branch (e.g. *Store #101*).
3. **Minor (16-bit):** Identifies a specific shelf, aisle, or department (e.g. *Aisle #4*).

### Ranging Beacons with `CLBeaconIdentityConstraint`

```swift
func startRanging(uuid: UUID) {
    let constraint = CLBeaconIdentityConstraint(uuid: uuid)
    let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "Store_Beacons")
    
    locationManager.startMonitoring(for: region)
    locationManager.startRangingBeacons(satisfying: constraint)
}

// Ranging Callback (Fired ~1Hz when in range)
func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
    for beacon in beacons {
        print("🎯 Beacon Major: \(beacon.major), Minor: \(beacon.minor), Proximity: \(beacon.proximity), Acc: \(beacon.accuracy)m, RSSI: \(beacon.rssi)")
    }
}
```

---

## 5. Interactive Sample in Project

Try the live interactive sample in the app:
• **Source View:** `BluetoothBeaconSampleView.swift`
• **Core Service:** `BluetoothBeaconService.swift`
• **Hub Navigation:** *Samples → Intermediate → Bluetooth & iBeacon Scanner*

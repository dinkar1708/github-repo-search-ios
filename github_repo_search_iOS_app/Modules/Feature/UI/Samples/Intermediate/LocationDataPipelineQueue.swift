//
//  LocationDataPipelineQueue.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/25.
//

import Foundation
import Network
import Observation

/// Unified SDK Telemetry Packet combining GPS and BLE data
struct SDKTelemetryPacket: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let speed: Double
    let batteryLevel: Float
    let isBackground: Bool
    let nearbyBeaconCount: Int
    let topBeaconUUID: String?
    let topBeaconRSSI: Int?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        speed: Double,
        batteryLevel: Float = 0.85,
        isBackground: Bool = false,
        nearbyBeaconCount: Int = 0,
        topBeaconUUID: String? = nil,
        topBeaconRSSI: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.speed = speed
        self.batteryLevel = batteryLevel
        self.isBackground = isBackground
        self.nearbyBeaconCount = nearbyBeaconCount
        self.topBeaconUUID = topBeaconUUID
        self.topBeaconRSSI = topBeaconRSSI
    }
}

/// Dynamic Pipeline Processing Metrics
struct PipelineMetrics {
    var totalPointsIngested: Int = 0
    var totalBatchesFlushed: Int = 0
    var totalBytesSent: Int = 0
    var pendingQueueCount: Int = 0
    var lastUploadLatencyMs: Double = 0.0
    var lastFlushTimestamp: Date? = nil
    var compressionRatioPercentage: Double = 68.5
}

/// Robust Local Ingestion Buffer and Upload Pipeline Queue with Network State Monitoring
@Observable
@MainActor
final class LocationDataPipelineQueue {
    static let shared = LocationDataPipelineQueue()

    private(set) var pendingQueue: [SDKTelemetryPacket] = []
    private(set) var metrics = PipelineMetrics()
    private(set) var isAutoFlushing: Bool = true
    private(set) var isOnline: Bool = true
    private(set) var connectionType: String = "Wi-Fi"
    var isSimulatingOffline: Bool = false
    private(set) var recentLogs: [LifecycleLogEntry] = []
    var batchSizeThreshold: Int = 10
    var autoFlushIntervalSeconds: Double = 15.0

    private var flushTimer: Timer?
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.sdk.telemetry.network.monitor")
    private let storageKey = "SDK_LOCAL_TELEMETRY_SPOOL_QUEUE"

    init() {
        restoreSpoolFromDisk()
        startNetworkMonitoring()
        startAutoFlushTimer()
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Network Connectivity Monitoring

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let wasOnline = self.isOnline
                self.isOnline = (path.status == .satisfied)

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = "Wi-Fi"
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = "Ethernet"
                } else {
                    self.connectionType = "No Connection"
                }

                let statusStr = self.isOnline ? "🟢 Online (\(self.connectionType))" : "🔴 Offline (Disconnected)"
                self.addLog("📶 [Network Path] Status: \(statusStr)")
                print("☁️ [DataPipeline] Network status changed: \(statusStr)")

                // Auto-flush queue backlog when returning online
                if !wasOnline && self.isOnline && !self.isSimulatingOffline && !self.pendingQueue.isEmpty {
                    self.addLog("⚡️ [Network Restored] Auto-flushing \(self.pendingQueue.count) spooled points")
                    self.flushBatch(trigger: "Auto Reconnect")
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    public func toggleSimulateOffline() {
        isSimulatingOffline.toggle()
        let modeStr = isSimulatingOffline ? "TUNNEL / OFFLINE (Mock)" : "ONLINE (Normal)"
        addLog("🕹️ Offline simulation toggled: \(modeStr)")
        print("☁️ [DataPipeline] Offline simulation is now \(isSimulatingOffline ? "ACTIVE (Spool only)" : "DISABLED (Live uploads)")")

        if !isSimulatingOffline && isOnline && !pendingQueue.isEmpty {
            addLog("⚡️ [Tunnel Exited] Reconnected - Uploading pending backlog")
            flushBatch(trigger: "Tunnel Exited")
        }
    }

    // MARK: - Ingestion

    func enqueuePacket(_ packet: SDKTelemetryPacket) {
        pendingQueue.append(packet)
        metrics.totalPointsIngested += 1
        metrics.pendingQueueCount = pendingQueue.count

        addLog("📥 [Ingest] Point (\(String(format: "%.4f", packet.latitude)), \(String(format: "%.4f", packet.longitude))) queued (Queue: \(pendingQueue.count)/\(batchSizeThreshold))")

        // Save spool locally
        saveSpoolToDisk()

        // Check threshold
        if pendingQueue.count >= batchSizeThreshold {
            flushBatch(trigger: "Batch Threshold (\(batchSizeThreshold) pts)")
        }
    }

    func enqueueFromLocation(latitude: Double, longitude: Double, accuracy: Double, speed: Double, isBackground: Bool, beacons: [DiscoveredBeacon]) {
        let topBeacon = beacons.first
        let packet = SDKTelemetryPacket(
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            speed: speed,
            batteryLevel: 0.90,
            isBackground: isBackground,
            nearbyBeaconCount: beacons.count,
            topBeaconUUID: topBeacon?.uuid.uuidString,
            topBeaconRSSI: topBeacon?.rssi
        )
        enqueuePacket(packet)
    }

    // MARK: - Batch Flushing & Cloud DWH Upload Simulation

    func flushBatch(trigger: String = "Manual") {
        guard !pendingQueue.isEmpty else {
            addLog("ℹ️ [Flush] Queue is empty, nothing to upload")
            return
        }

        // Offline protection check
        let effectiveOnline = isOnline && !isSimulatingOffline
        guard effectiveOnline else {
            addLog("⚠️ [Offline Spool] Network unreachable (\(isSimulatingOffline ? "Mock Tunnel" : "Offline")). \(pendingQueue.count) points safely buffered on disk.")
            print("☁️ [DataPipeline] Cannot flush: Device is offline. Data safely spooled in local storage.")
            return
        }

        let batchToUpload = Array(pendingQueue.prefix(batchSizeThreshold))
        let count = batchToUpload.count

        addLog("🚀 [Pipeline Flush] Trigger: \(trigger) - Transmitting \(count) points via \(connectionType)...")
        print("☁️ [DataPipeline] Flushing batch of \(count) telemetry packets...")

        // Simulate network payload size & gzip compression
        let rawByteSize = count * 240 // ~240 bytes per structured JSON packet
        let compressedBytes = Int(Double(rawByteSize) * 0.32) // ~68% compression

        let startTime = Date()

        // Simulate async cloud ingestion (AWS S3 / Kinesis / Snowflake endpoint)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            let latency = Date().timeIntervalSince(startTime) * 1000.0

            self.pendingQueue.removeFirst(min(count, self.pendingQueue.count))
            self.metrics.pendingQueueCount = self.pendingQueue.count
            self.metrics.totalBatchesFlushed += 1
            self.metrics.totalBytesSent += compressedBytes
            self.metrics.lastUploadLatencyMs = latency
            self.metrics.lastFlushTimestamp = Date()

            self.saveSpoolToDisk()

            self.addLog("✅ [Pipeline Success] Ingested \(count) points (Payload: \(compressedBytes) bytes, Latency: \(Int(latency))ms)")
            print("☁️ [DataPipeline] Batch successfully ingested by Cloud DWH. Remaining queue: \(self.pendingQueue.count)")
        }
    }

    func clearAllData() {
        pendingQueue.removeAll()
        metrics = PipelineMetrics()
        recentLogs.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        addLog("🧹 Cleared local queue spool and pipeline metrics")
    }

    func toggleAutoFlush() {
        isAutoFlushing.toggle()
        if isAutoFlushing {
            startAutoFlushTimer()
            addLog("⏱️ Auto-flush timer enabled (every \(Int(autoFlushIntervalSeconds))s)")
        } else {
            flushTimer?.invalidate()
            flushTimer = nil
            addLog("⏸️ Auto-flush timer paused")
        }
    }

    // MARK: - Local Persistence (Offline Spooling)

    private func saveSpoolToDisk() {
        do {
            let data = try JSONEncoder().encode(pendingQueue)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("⚠️ [DataPipeline] Failed to save queue spool: \(error)")
        }
    }

    private func restoreSpoolFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let items = try JSONDecoder().decode([SDKTelemetryPacket].self, from: data)
            self.pendingQueue = items
            self.metrics.pendingQueueCount = items.count
            if !items.isEmpty {
                addLog("💾 Restored \(items.count) pending telemetry points from local disk spool")
            }
        } catch {
            print("⚠️ [DataPipeline] Failed to decode spool: \(error)")
        }
    }

    private func startAutoFlushTimer() {
        flushTimer?.invalidate()
        flushTimer = Timer.scheduledTimer(withTimeInterval: autoFlushIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isAutoFlushing, !self.pendingQueue.isEmpty else { return }
                self.flushBatch(trigger: "Auto-Timer (\(Int(self.autoFlushIntervalSeconds))s)")
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
}

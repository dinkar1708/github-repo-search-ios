//
//  LocationSDKPipelineOverviewView.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/25.
//

import SwiftUI

/// Architecture Overview & Interactive Data Pipeline Simulator for Location and BLE Data Ingestion
public struct LocationSDKPipelineOverviewView: View {
    @StateObject private var pipeline = LocationDataPipelineQueue.shared
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Architecture Card
                PipelineArchitectureHeaderCard()

                // Live Pipeline Pipeline Control & Metric Card
                PipelineLiveDemoCard(
                    metrics: pipeline.metrics,
                    pendingCount: pipeline.pendingQueue.count,
                    batchThreshold: pipeline.batchSizeThreshold,
                    isAutoFlushing: pipeline.isAutoFlushing,
                    isOnline: pipeline.isOnline,
                    connectionType: pipeline.connectionType,
                    isSimulatingOffline: pipeline.isSimulatingOffline,
                    onEnqueueSample: {
                        let mockLat = 35.6812 + Double.random(in: -0.005...0.005)
                        let mockLon = 139.7671 + Double.random(in: -0.005...0.005)
                        pipeline.enqueueFromLocation(
                            latitude: mockLat,
                            longitude: mockLon,
                            accuracy: Double.random(in: 3.5...9.0),
                            speed: Double.random(in: 1.0...4.5),
                            isBackground: false,
                            beacons: []
                        )
                    },
                    onEnqueueBatch: {
                        for _ in 0..<5 {
                            let mockLat = 35.6812 + Double.random(in: -0.005...0.005)
                            let mockLon = 139.7671 + Double.random(in: -0.005...0.005)
                            pipeline.enqueueFromLocation(
                                latitude: mockLat,
                                longitude: mockLon,
                                accuracy: Double.random(in: 3.5...9.0),
                                speed: Double.random(in: 1.0...4.5),
                                isBackground: true,
                                beacons: []
                            )
                        }
                    },
                    onFlushNow: {
                        pipeline.flushBatch(trigger: "Manual Button")
                    },
                    onToggleAutoFlush: {
                        pipeline.toggleAutoFlush()
                    },
                    onToggleSimulateOffline: {
                        pipeline.toggleSimulateOffline()
                    },
                    onClear: {
                        pipeline.clearAllData()
                    }
                )

                // Battery vs. Accuracy Tradeoff Comparison Matrix
                BatteryOptimizationMatrixCard()

                // Mobile SDK Engineering Best Practices
                SDKBestPracticesCard()

                // Live Event Log
                LifecycleEventLogCard(
                    logs: pipeline.recentLogs,
                    onClear: { pipeline.clearAllData() }
                )
            }
            .padding()
        }
        .navigationTitle("Location & SDK Pipeline")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🚀 [PipelineSample] LocationSDKPipelineOverviewView appeared.")
        }
    }
}

// MARK: - Subcomponents

struct PipelineArchitectureHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "server.rack")
                    .font(.title)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Mobile Telemetry SDK Architecture")
                        .font(.headline)
                    Text("Edge Collection → Buffer → Batch → Cloud Ingestion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                ArchitectureStepRow(step: "1", title: "Edge Collection", detail: "GPS fixes & BLE Beacon RSSI packets captured with battery-aware throttling")
                ArchitectureStepRow(step: "2", title: "Local Spool Buffer", detail: "Thread-safe local disk queue prevents data loss during tunnel/offline states")
                ArchitectureStepRow(step: "3", title: "Adaptive Batching", detail: "Gzip compressed batch payload (~68% bandwidth reduction)")
                ArchitectureStepRow(step: "4", title: "Cloud DWH Ingestion", detail: "Low-latency REST / Kinesis / S3 upload for real-time spatial analytics")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ArchitectureStepRow: View {
    let step: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.purple))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PipelineLiveDemoCard: View {
    let metrics: PipelineMetrics
    let pendingCount: Int
    let batchThreshold: Int
    let isAutoFlushing: Bool
    let isOnline: Bool
    let connectionType: String
    let isSimulatingOffline: Bool
    let onEnqueueSample: () -> Void
    let onEnqueueBatch: () -> Void
    let onFlushNow: () -> Void
    let onToggleAutoFlush: () -> Void
    let onToggleSimulateOffline: () -> Void
    let onClear: () -> Void

    var networkStatusColor: Color {
        if isSimulatingOffline {
            return .orange
        }
        return isOnline ? .green : .red
    }

    var networkStatusText: String {
        if isSimulatingOffline {
            return "🟠 Mock Tunnel (Offline)"
        }
        return isOnline ? "🟢 Online (\(connectionType))" : "🔴 Disconnected"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundColor(.blue)
                Text("Live Data Pipeline Ingestion")
                    .font(.headline)
                Spacer()
                Button(action: onToggleAutoFlush) {
                    Text(isAutoFlushing ? "Auto-Flush ON" : "Auto-Flush OFF")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isAutoFlushing ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                        .foregroundColor(isAutoFlushing ? .green : .secondary)
                        .cornerRadius(6)
                }
            }

            // Network Connectivity Row
            HStack {
                Label("Network: \(networkStatusText)", systemImage: isSimulatingOffline ? "antenna.radiowaves.left.and.right.slash" : (isOnline ? "wifi" : "wifi.slash"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(networkStatusColor)

                Spacer()

                Button(action: onToggleSimulateOffline) {
                    HStack(spacing: 4) {
                        Image(systemName: isSimulatingOffline ? "bolt.slash.fill" : "bolt.fill")
                        Text(isSimulatingOffline ? "Exit Tunnel" : "Sim Tunnel (Offline)")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isSimulatingOffline ? Color.orange.opacity(0.15) : Color.blue.opacity(0.1))
                    .foregroundColor(isSimulatingOffline ? .orange : .blue)
                    .cornerRadius(6)
                }
            }

            Divider()

            // Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                MetricItem(label: "Pending Queue", value: "\(pendingCount) pts")
                MetricItem(label: "Total Ingested", value: "\(metrics.totalPointsIngested)")
                MetricItem(label: "Batches Flushed", value: "\(metrics.totalBatchesFlushed)")
                MetricItem(label: "Bytes Sent", value: "\(metrics.totalBytesSent) B")
                MetricItem(label: "Last Latency", value: "\(Int(metrics.lastUploadLatencyMs)) ms")
                MetricItem(label: "Compression", value: "\(Int(metrics.compressionRatioPercentage))%")
            }

            // Action Buttons
            HStack(spacing: 8) {
                Button("+1 Point") { onEnqueueSample() }
                    .font(.caption)
                    .buttonStyle(.bordered)

                Button("+5 Batch") { onEnqueueBatch() }
                    .font(.caption)
                    .buttonStyle(.bordered)

                Spacer()

                Button("Flush Cloud") { onFlushNow() }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                Button("Reset") { onClear() }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BatteryOptimizationMatrixCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Battery vs. Accuracy Tradeoff Matrix")
                .font(.headline)

            VStack(spacing: 6) {
                MatrixRow(mode: "Navigation GPS", accuracy: "Best (< 5m)", drain: "High (~5-8%/hr)", useCase: "Turn-by-turn routing")
                MatrixRow(mode: "Significant Changes", accuracy: "~500m+", drain: "Ultra Low (<0.5%/day)", useCase: "City-level travel tracking")
                MatrixRow(mode: "Circular Geofence", accuracy: "50m - 100m", drain: "Very Low (~1%/day)", useCase: "Store entry / departure alerts")
                MatrixRow(mode: "iBeacon Ranging", accuracy: "0.1m - 3m", drain: "Moderate (~2%/hr)", useCase: "Indoor room-level positioning")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MatrixRow: View {
    let mode: String
    let accuracy: String
    let drain: String
    let useCase: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(mode)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text(drain)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(drain.contains("High") ? .red : (drain.contains("Moderate") ? .orange : .green))
            }

            HStack {
                Text("Acc: \(accuracy)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Use: \(useCase)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(6)
    }
}

struct SDKBestPracticesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Production SDK Architecture Principles")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                PrincipleBullet(title: "1. Graceful Permission Degradation", text: "Support WhenInUse gracefully before prompting for Always background access.")
                PrincipleBullet(title: "2. Zero Foreground UI Blocking", text: "Offload CoreBluetooth and GPS packet serialization to dedicated background serial queues.")
                PrincipleBullet(title: "3. Power-Aware Distance Filters", text: "Dynamically increase distanceFilter (e.g. from 5m to 50m) when speed drops to stationary.")
                PrincipleBullet(title: "4. Network Resiliency (Spooling)", text: "Always spool uncommitted telemetry to disk so zero points are lost during network drops.")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct PrincipleBullet: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

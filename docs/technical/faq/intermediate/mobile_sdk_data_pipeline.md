# Mobile SDK Data Pipeline: Location & BLE Telemetry Ingestion

An end-to-end engineering guide on designing high-throughput, low-power mobile SDKs for location tracking, BLE/beacon detection, edge buffering, adaptive batching, and cloud data warehouse (DWH) ingestion.

---

## 1. End-to-End System Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                       Mobile Client                         │
│                                                             │
│  [ CoreLocation GPS ] ──┐                                   │
│                         ├──► [ Telemetry Queue Buffer ]     │
│  [ CoreBluetooth BLE ] ─┘             │                     │
│                                       ▼                     │
│                            [ Local SQLite / Spool ]         │
│                                       │ (Adaptive Batching) │
│                                       ▼                     │
│                             [ Gzip Compression ]            │
└───────────────────────────────────────┬─────────────────────┘
                                        │ (HTTPS REST / Protobuf / MQTT)
                                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Ingestion Layer                    │
│                                                             │
│  [ AWS API Gateway / ALB ] ──► [ Kinesis Data Stream ]      │
│                                       │                     │
│                                       ▼                     │
│                              [ S3 Parquet Lake ]            │
│                                       │                     │
│                                       ▼                     │
│                        [ Snowflake / BigQuery DWH ]         │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Key SDK Engineering Principles

### 1. Zero UI Thread Interruption
• Never execute JSON encoding, cryptographic hashing, or SQLite I/O on the `@MainActor`.
• Use dedicated background serial queues (`DispatchQueue(label: "com.sdk.telemetry.queue")`) or Swift Concurrency actors.

### 2. Network Resiliency & Disk Spooling
• Network connectivity in mobile environments fluctuates constantly (subways, underground garages, dead zones).
• All incoming GPS and BLE packets must be spooled immediately to durable local disk storage before acknowledging collection.
• When internet connectivity is restored, batches are uploaded in FIFO order.

### 3. Adaptive Batching Strategy
Rather than opening an HTTP connection for every single GPS ping (which destroys battery and exhausts radio states), use **Adaptive Batching**:
• **Batch Count Threshold:** Flush when $\ge 15$ points accumulate.
• **Time-based Interval:** Flush every 30 seconds if uncommitted points exist.
• **Network-aware Upload:** If on Cellular low-data mode, buffer longer; if connected to Wi-Fi, flush immediately.

---

## 3. Battery Consumption vs. Sampling Rate Optimization

| Location Mode | Distance Filter | Battery Drain | Optimal Use Case |
| :--- | :--- | :--- | :--- |
| **High Precision GPS** | $0\text{m} - 5\text{m}$ | $5 - 8\% \text{ / hour}$ | Active navigation, fast highway movement |
| **Balanced Pedestrian** | $10\text{m} - 25\text{m}$ | $1.5 - 3\% \text{ / hour}$ | Walking pedestrian tracking, foot traffic analysis |
| **Cellular Significant Change** | $\sim 500\text{m}+$ | $<0.5\% \text{ / day}$ | Long-distance travel, passive background monitoring |
| **Geofencing & iBeacons** | $50\text{m} - 100\text{m}$ | $\sim 1\% \text{ / day}$ | Store arrivals, boundary check-ins, indoor micro-location |

---

## 4. Interactive Sample & Implementation in Project

• **UI View:** `LocationSDKPipelineOverviewView.swift`
• **Queue Buffer Service:** `LocationDataPipelineQueue.swift`
• **Hub Navigation:** *Samples → Intermediate → Location & SDK Pipeline*

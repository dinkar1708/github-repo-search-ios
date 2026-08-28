//
//  OfflineBackgroundSyncScheduler.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/28.
//

import Foundation
import BackgroundTasks

// MARK: - Protocol Definition

/// Protocol managing OS-Level BGTaskScheduler (iOS equivalent of Android WorkManager)
@MainActor
protocol OfflineBackgroundSyncSchedulerProtocol: Sendable {
    func register()
    func scheduleBackgroundSync(earliestBeginInSeconds: TimeInterval)
    func triggerManualSimulation() async -> (syncedCount: Int, log: String)
}

// MARK: - Production BGTaskScheduler Manager

/// Production BackgroundTasks Manager for Periodic & Opportunistic Offline SQLite Data Sync
final class OfflineBackgroundSyncScheduler: OfflineBackgroundSyncSchedulerProtocol, @unchecked Sendable {
    static let shared = OfflineBackgroundSyncScheduler()

    /// Unique Task Identifier declared in Info.plist BGTaskSchedulerPermittedIdentifiers
    static let taskIdentifier = "dinakar.app.github-repo-search-iOS-app.offline-sync"

    private var isRegistered = false

    private init() {}

    // MARK: - Registration (Called at App Launch)

    /// Registers the background task handler with the iOS Operating System.
    /// Must be called during app initialization (e.g. LauncherView.init or AppDelegate) before app finish launching.
    func register() {
        guard !isRegistered else { return }
        isRegistered = true

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            self?.handleBackgroundSync(task: appRefreshTask)
        }

        print("🌙 [BGTaskScheduler] Registered background task identifier: '\(Self.taskIdentifier)'")
    }

    // MARK: - Scheduling Next Background Run

    /// Submits a background sync request to the iOS kernel.
    /// - Parameter earliestBeginInSeconds: Delay before the OS considers executing the task (Default: 15 minutes).
    func scheduleBackgroundSync(earliestBeginInSeconds: TimeInterval = 15 * 60) {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: earliestBeginInSeconds)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("🗓️ [BGTaskScheduler] Scheduled offline sync task. Earliest begin: \(request.earliestBeginDate?.formatted() ?? "now")")
        } catch {
            print("⚠️ [BGTaskScheduler] Could not schedule background task: \(error.localizedDescription)")
        }
    }

    // MARK: - Background Task Execution Handler

    /// Invoked by iOS when background constraints (power, Wi-Fi, idle time) are met.
    private func handleBackgroundSync(task: BGAppRefreshTask) {
        // 1. Immediately schedule the next periodic background sync request
        scheduleBackgroundSync()

        // 2. Set up cancellation handler if the OS runs out of background execution time (~30 seconds)
        let syncTask = Task { @MainActor in
            do {
                print("🌙 [BGTaskScheduler] App awakened by iOS kernel! Starting background SQLite sync...")
                let syncedItems = try await SwiftDataOfflineRepository.shared.syncAllPendingRepositories()
                print("✅ [BGTaskScheduler] Successfully synced \(syncedItems.count) offline items in background.")
                task.setTaskCompleted(success: true)
            } catch {
                print("❌ [BGTaskScheduler] Background sync failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            print("⏰ [BGTaskScheduler] Background execution window expired by OS! Cancelling...")
            syncTask.cancel()
        }
    }

    // MARK: - Simulator & UI Simulation Helper

    /// Simulates the exact execution flow of an iOS BGAppRefreshTask for local UI testing and debugging
    @MainActor
    func triggerManualSimulation() async -> (syncedCount: Int, log: String) {
        let startTime = Date()
        print("🧪 [BGTaskScheduler Simulation] Simulating OS background wake-up event...")

        do {
            let syncedItems = try await SwiftDataOfflineRepository.shared.syncAllPendingRepositories()
            let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000.0)
            let log = "🌙 [BGTaskScheduler Simulation] Completed background sync of \(syncedItems.count) items in \(latencyMs)ms."
            print("✅ \(log)")
            return (syncedItems.count, log)
        } catch {
            let errorLog = "❌ [BGTaskScheduler Simulation] Failed: \(error.localizedDescription)"
            print(errorLog)
            return (0, errorLog)
        }
    }
}

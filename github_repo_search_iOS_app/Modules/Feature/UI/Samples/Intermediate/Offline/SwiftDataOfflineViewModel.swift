//
//  SwiftDataOfflineViewModel.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/28.
//

import Foundation
import Observation
import SwiftData

/// Modern Swift 6 @Observable ViewModel leveraging Structured Concurrency and Actor Isolation
@Observable
@MainActor
final class SwiftDataOfflineViewModel {
    // MARK: - Observable Properties (No @Published Needed in Swift 6 / iOS 17+)

    var repositories: [OfflineRepoItem] = []
    var tableStats: (repos: Int, owners: Int, tags: Int, logs: Int) = (0, 0, 0, 0)
    var recentLogs: [LifecycleLogEntry] = []
    var isSyncing: Bool = false
    var isImporting: Bool = false

    var searchText: String = "" {
        didSet { applyFilters() }
    }
    var selectedFilter: Int = 0 { // 0: All, 1: Bookmarked, 2: Pending Sync
        didSet { applyFilters() }
    }
    var autoSyncEnabled: Bool = true
    var statusMessage: String = "Ready. Swift 6 Concurrency & @Observable active."

    @ObservationIgnored
    private var allFetchedRepositories: [OfflineRepoItem] = []

    @ObservationIgnored
    private let repository: OfflineRepositoryProtocol

    // MARK: - Initializer & Dependency Injection

    init(repository: OfflineRepositoryProtocol? = nil) {
        self.repository = repository ?? SwiftDataOfflineRepository.shared
    }

    // MARK: - Data Loading & Filtering

    func onAppear() {
        Task {
            do {
                try await repository.seedDefaultRepositoriesIfNeeded()
                await reloadData()
                addLog("💾 [Swift 6 Observation] State initialized without @Published boilerplate")
            } catch {
                statusMessage = "⚠️ Initialization failed: \(error.localizedDescription)"
            }
        }
    }

    func reloadData() async {
        do {
            allFetchedRepositories = try await repository.fetchRepositories(matching: "", filter: 0)
            tableStats = await repository.fetchTableStats()
            applyFilters()
        } catch {
            statusMessage = "❌ Fetch failed: \(error.localizedDescription)"
        }
    }

    private func applyFilters() {
        repositories = allFetchedRepositories.filter { repo in
            let matchesSearch = searchText.isEmpty ||
                repo.name.localizedCaseInsensitiveContains(searchText) ||
                repo.repoDescription.localizedCaseInsensitiveContains(searchText) ||
                (repo.owner?.login.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesFilter: Bool
            switch selectedFilter {
            case 1: matchesFilter = repo.isBookmarked
            case 2: matchesFilter = !repo.isSynced
            default: matchesFilter = true
            }

            return matchesSearch && matchesFilter
        }
    }

    var pendingSyncCount: Int {
        allFetchedRepositories.filter { !$0.isSynced }.count
    }

    var syncedCount: Int {
        allFetchedRepositories.filter { $0.isSynced }.count
    }

    // MARK: - Swift 6 Structured Concurrency Database Actions

    func addSampleRepository() {
        let randomID = Int.random(in: 100...999)
        let sampleNames = ["swift-testing", "vapor", "pointfreeco", "grpc-swift", "composable-architecture", "swift-collections"]
        let chosenName = sampleNames.randomElement() ?? "swift-library-\(randomID)"
        let randomStars = Int.random(in: 500...25000)

        // 1. Table 2: Owner
        let owner = OfflineRepoOwner(
            id: "owner_\(randomID)",
            login: "developer_\(randomID)",
            company: "Swift 6 Concurrency Lab",
            location: "Tokyo, JP"
        )

        // 2. Table 1: Repository
        let newRepo = OfflineRepoItem(
            id: "\(randomID)",
            name: chosenName,
            repoDescription: "Modern Swift 6 @Observable model with structured async/await tasks.",
            starCount: randomStars,
            forkCount: Int(Double(randomStars) * 0.18),
            language: "Swift",
            owner: owner,
            isBookmarked: false,
            isSynced: false,
            syncStatus: "pending"
        )

        // 3. Table 3: Tags
        newRepo.tags = [
            OfflineRepoTag(name: "swift-6", repository: newRepo),
            OfflineRepoTag(name: "observable", repository: newRepo)
        ]

        // 4. Table 4: Initial Audit Log
        newRepo.syncAuditLogs = [
            OfflineSyncAuditLog(actionType: "LOCAL_INSERT", serverStatusCode: 201, syncLatencyMs: 0.0, repository: newRepo)
        ]

        Task {
            do {
                try await repository.insertRepository(item: newRepo)
                addLog("📥 [DB Insert] '\(chosenName)' saved via Swift 6 Actor task (isSynced: false)")
                statusMessage = "📥 Inserted '\(chosenName)' into local database."
                await reloadData()

                if autoSyncEnabled {
                    await syncSingle(repo: newRepo)
                }
            } catch {
                statusMessage = "❌ Insert failed: \(error.localizedDescription)"
            }
        }
    }

    func importBatchBackground() {
        isImporting = true
        statusMessage = "⚡️ Background import running on isolated @ModelActor..."

        let batch: [(id: String, name: String, desc: String, stars: Int, forks: Int, ownerLogin: String, ownerCompany: String, tags: [String])] = [
            (id: "101", name: "swift-protobuf", desc: "Plugin and runtime library for using Google Protocol Buffers with Swift.", stars: 4900, forks: 620, ownerLogin: "apple", ownerCompany: "Apple Inc.", tags: ["protobuf", "networking"]),
            (id: "102", name: "swift-metrics", desc: "Metrics API package for Swift applications and servers.", stars: 1200, forks: 150, ownerLogin: "apple", ownerCompany: "Apple Inc.", tags: ["telemetry", "metrics"]),
            (id: "103", name: "swift-log", desc: "A Logging API for Swift.", stars: 3900, forks: 480, ownerLogin: "apple", ownerCompany: "Apple Inc.", tags: ["logging", "observability"]),
            (id: "104", name: "swift-crypto", desc: "Open-source implementation of Apple CryptoKit for Swift.", stars: 3100, forks: 380, ownerLogin: "apple", ownerCompany: "Apple Inc.", tags: ["security", "cryptography"]),
            (id: "105", name: "swift-nio", desc: "Event-driven asynchronous network application framework for Swift.", stars: 7800, forks: 950, ownerLogin: "apple", ownerCompany: "Apple Inc.", tags: ["networking", "async"])
        ]

        Task {
            do {
                // Background execution on isolated actor
                let count = try await repository.importBatchBackground(items: batch)
                isImporting = false
                addLog("⚡️ [@ModelActor Task] Successfully imported \(count) items without blocking main thread")
                statusMessage = "✅ @ModelActor imported \(count) multi-table items (Pending Sync)."
                await reloadData()

                if autoSyncEnabled {
                    await syncAllPending()
                }
            } catch {
                isImporting = false
                statusMessage = "❌ Background import error: \(error.localizedDescription)"
            }
        }
    }

    func toggleBookmark(repo: OfflineRepoItem) {
        Task {
            do {
                try await repository.toggleBookmark(for: repo)
                statusMessage = "⭐️ \(repo.name) bookmark: \(repo.isBookmarked ? "Saved" : "Removed")"
                await reloadData()
            } catch {
                statusMessage = "❌ Bookmark failed: \(error.localizedDescription)"
            }
        }
    }

    func deleteRepository(repo: OfflineRepoItem) {
        let name = repo.name
        Task {
            do {
                try await repository.deleteRepository(item: repo)
                addLog("🗑 [DB Delete] Purged '\(name)' and cascaded child records from disk")
                statusMessage = "🗑 Deleted '\(name)' from database."
                await reloadData()
            } catch {
                statusMessage = "❌ Delete failed: \(error.localizedDescription)"
            }
        }
    }

    func syncSingle(repo: OfflineRepoItem) async {
        let name = repo.name
        addLog("🌐 [MockServerAPI] Hello! Async task calling POST /api/v1/sync for '\(name)'...")
        do {
            let (_, latency) = try await repository.syncRepositoryToServer(item: repo)
            addLog("✅ [MockServerAPI] Server responded 200 OK for '\(name)' (Latency: \(Int(latency))ms)")
            statusMessage = "✅ Synced '\(name)' to server API."
            await reloadData()
        } catch {
            addLog("❌ [SyncError] Failed to sync '\(name)': \(error.localizedDescription)")
        }
    }

    func syncAllPending() async {
        guard !isSyncing else { return }
        isSyncing = true
        addLog("🚀 [Structured Concurrency] Starting batch synchronization for pending repositories...")

        do {
            let syncedItems = try await repository.syncAllPendingRepositories()
            isSyncing = false
            addLog("🎉 [SyncEngine] Successfully synced \(syncedItems.count) pending repositories to Cloud Server!")
            statusMessage = "🎉 Batch sync complete: \(syncedItems.count) items synced."
            await reloadData()
        } catch {
            isSyncing = false
            addLog("❌ [SyncEngine] Batch sync error: \(error.localizedDescription)")
        }
    }

    /// Invokes the OS-level BGTaskScheduler background synchronization workflow
    func simulateBGTaskSchedulerRefresh() {
        guard !isSyncing else { return }
        isSyncing = true
        addLog("🌙 [BGTaskScheduler] User tapped 'Invoke BGTaskScheduler'!")
        addLog("📱 [Scheduler] Submitting task request '\(OfflineBackgroundSyncScheduler.taskIdentifier)'...")
        addLog("⚡️ [Scheduler Worker] Calling SwiftData offline repository to sync pending records...")

        Task {
            let (count, log) = await OfflineBackgroundSyncScheduler.shared.triggerManualSimulation()
            isSyncing = false
            addLog(log)
            statusMessage = "🌙 BGTaskScheduler completed: Synced \(count) pending items to Cloud Server."
            await reloadData()
        }
    }

    func seedDefaults() {
        Task {
            do {
                try await repository.seedDefaultRepositoriesIfNeeded()
                addLog("🌱 [DB Seed] Inserted initial multi-table records")
                statusMessage = "🌱 Seeded 4 relational tables."
                await reloadData()
            } catch {
                statusMessage = "❌ Seeding failed: \(error.localizedDescription)"
            }
        }
    }

    func clearAll() {
        Task {
            do {
                try await repository.clearAllDatabase()
                recentLogs.removeAll()
                addLog("🧹 [DB Clear] Cleared all 4 relational tables and logs")
                statusMessage = "🧹 Cleared all tables."
                await reloadData()
            } catch {
                statusMessage = "❌ Clear failed: \(error.localizedDescription)"
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

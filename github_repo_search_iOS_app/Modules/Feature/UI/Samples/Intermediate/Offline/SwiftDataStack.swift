//
//  SwiftDataStack.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/28.
//

import Foundation
import SwiftData

// MARK: - Data Layer: Database Stack Protocol

/// Abstract Data Layer Protocol providing ModelContainer and ModelContext access
@MainActor
protocol SwiftDataStackProtocol: Sendable {
    var container: ModelContainer { get }
    var mainContext: ModelContext { get }
    nonisolated func createBackgroundImporter() -> BackgroundOfflineImporter
    func wipeAllData() throws
}

// MARK: - Production SwiftData Stack Implementation

/// Local Data Source: Manages ModelContainer initialization, schema configuration, and database context lifecycle
@MainActor
final class SwiftDataStack: SwiftDataStackProtocol, @unchecked Sendable {
    static let shared = SwiftDataStack()

    let container: ModelContainer

    private init(isInMemory: Bool = false) {
        do {
            let schema = Schema([
                OfflineRepoItem.self,
                OfflineRepoOwner.self,
                OfflineRepoTag.self,
                OfflineSyncAuditLog.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isInMemory)
            self.container = try ModelContainer(for: schema, configurations: [configuration])
            print("💾 [SwiftDataStack] Initialized ModelContainer (4 Relational Tables, inMemory: \(isInMemory)).")
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    /// Primary UI Thread Context (tied to @MainActor)
    /// ⚠️ IMPORTANT: Accessing or mutating models on `mainContext` from a background thread will crash.
    /// It is strictly reserved for SwiftUI views and @MainActor ViewModels.
    var mainContext: ModelContext {
        container.mainContext
    }

    // MARK: - 🎓 Critical Swift 6 Concurrency Architecture: nonisolated ModelActor Factory
    //
    // ❓ WHY IS THIS `nonisolated`?
    // -----------------------------------------------------------------------------------------
    // 1. `SwiftDataStack` is a `@MainActor` class because `mainContext` belongs to the main thread.
    // 2. However, background tasks (e.g. network downloaders, sync engines, batch importers)
    //    need to instantiate background database workers WITHOUT hopping to the Main Thread!
    // 3. By marking this method `nonisolated`:
    //    - Any thread, actor, or Task can call `createBackgroundImporter()` synchronously.
    //    - It safely reads `self.container` (which is `Sendable` and thread-safe).
    //    - Zero context-switch penalty: The main thread is never interrupted or blocked.
    //
    // ❓ HOW DOES `@ModelActor` WORK UNDER THE HOOD?
    // -----------------------------------------------------------------------------------------
    // When `BackgroundOfflineImporter(modelContainer: container)` is initialized:
    // • SwiftData synthesizes a private `modelExecutor: any ModelExecutor` for this actor.
    // • SwiftData creates an isolated `modelContext` bound EXCLUSIVELY to this background actor's serial queue.
    // • Any heavy insert/save operations run 100% off the Main Thread, preserving 120 FPS UI smoothness.
    // -----------------------------------------------------------------------------------------
    nonisolated func createBackgroundImporter() -> BackgroundOfflineImporter {
        BackgroundOfflineImporter(modelContainer: container)
    }

    /// Wipes all tables from the local SQLite store
    func wipeAllData() throws {
        try mainContext.delete(model: OfflineSyncAuditLog.self)
        try mainContext.delete(model: OfflineRepoTag.self)
        try mainContext.delete(model: OfflineRepoItem.self)
        try mainContext.delete(model: OfflineRepoOwner.self)
        try mainContext.save()
        print("🧹 [SwiftDataStack] Cleared all 4 tables from disk.")
    }
}

// MARK: - Isolated Background Worker (ModelActor)

/// Swift Concurrency Background Worker isolated from MainActor
///
/// 🎓 Deep Dive on `@ModelActor`:
/// 1. Concurrency Isolation: All methods inside this actor run on an asynchronous background executor.
/// 2. Thread-Safe ModelContext: SwiftData provides an implicit `modelContext` property specifically
///    tied to this actor's serial execution queue.
/// 3. Zero UI Freezes: You can parse 10,000 JSON records, create `@Model` instances, and call `modelContext.save()`
///    without dropping a single frame on the user's screen.
@ModelActor
actor BackgroundOfflineImporter {
    func importBatchItems(items: [(id: String, name: String, desc: String, stars: Int, forks: Int, ownerLogin: String, ownerCompany: String, tags: [String])]) throws -> Int {
        var cachedOwners: [String: OfflineRepoOwner] = [:]

        for item in items {
            let ownerKey = item.ownerLogin.lowercased()
            let owner: OfflineRepoOwner
            if let existing = cachedOwners[ownerKey] {
                owner = existing
            } else {
                let newOwner = OfflineRepoOwner(
                    id: "owner_\(ownerKey)",
                    login: item.ownerLogin,
                    company: item.ownerCompany
                )
                cachedOwners[ownerKey] = newOwner
                owner = newOwner
            }

            let repo = OfflineRepoItem(
                id: item.id,
                name: item.name,
                repoDescription: item.desc,
                starCount: item.stars,
                forkCount: item.forks,
                language: "Swift",
                owner: owner,
                isBookmarked: false,
                isSynced: false,
                syncStatus: "pending"
            )

            let tagModels = item.tags.map { OfflineRepoTag(name: $0, repository: repo) }
            repo.tags = tagModels

            let initialAudit = OfflineSyncAuditLog(
                actionType: "MODEL_ACTOR_INSERT",
                serverStatusCode: 201,
                syncLatencyMs: 0.0,
                repository: repo
            )
            repo.syncAuditLogs = [initialAudit]

            // Inserting parent repo automatically cascades insertion of associated owner, tags, and audit logs
            modelContext.insert(repo)
        }

        try modelContext.save()
        print("⚡️ [BackgroundOfflineImporter] Successfully persisted \(items.count) multi-table items on background thread.")
        return items.count
    }
}

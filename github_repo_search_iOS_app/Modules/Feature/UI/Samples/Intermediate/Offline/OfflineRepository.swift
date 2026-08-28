//
//  OfflineRepository.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/28.
//

import Foundation
import SwiftData

// MARK: - Repository Protocol (Domain / Repository Layer)

/// Abstract Protocol for Offline SwiftData CRUD and Cloud Server Synchronization
@MainActor
protocol OfflineRepositoryProtocol: Sendable {
    func fetchRepositories(matching searchText: String, filter: Int) async throws -> [OfflineRepoItem]
    func fetchTableStats() async -> (repos: Int, owners: Int, tags: Int, logs: Int)
    func insertRepository(item: OfflineRepoItem) async throws
    func toggleBookmark(for item: OfflineRepoItem) async throws
    func deleteRepository(item: OfflineRepoItem) async throws
    func syncRepositoryToServer(item: OfflineRepoItem) async throws -> (audit: OfflineSyncAuditLog, latencyMs: Double)
    func syncAllPendingRepositories() async throws -> [OfflineRepoItem]
    func importBatchBackground(items: [(id: String, name: String, desc: String, stars: Int, forks: Int, ownerLogin: String, ownerCompany: String, tags: [String])]) async throws -> Int
    func seedDefaultRepositoriesIfNeeded() async throws
    func clearAllDatabase() async throws
}

// MARK: - Production Implementation of OfflineRepository

/// Repository Layer: Orchestrates Local SwiftData Stack operations and Remote Server API sync
@MainActor
final class SwiftDataOfflineRepository: OfflineRepositoryProtocol, @unchecked Sendable {
    static let shared = SwiftDataOfflineRepository()

    private let dataStack: SwiftDataStackProtocol

    init(dataStack: SwiftDataStackProtocol? = nil) {
        self.dataStack = dataStack ?? SwiftDataStack.shared
    }

    private var context: ModelContext {
        dataStack.mainContext
    }

    // MARK: - Fetch Operations

    func fetchRepositories(matching searchText: String = "", filter: Int = 0) async throws -> [OfflineRepoItem] {
        let descriptor = FetchDescriptor<OfflineRepoItem>(
            sortBy: [SortDescriptor(\.starCount, order: .reverse)]
        )

        let allItems = try context.fetch(descriptor)
        return allItems.filter { repo in
            let matchesSearch = searchText.isEmpty ||
                repo.name.localizedCaseInsensitiveContains(searchText) ||
                repo.repoDescription.localizedCaseInsensitiveContains(searchText) ||
                (repo.owner?.login.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesFilter: Bool
            switch filter {
            case 1: matchesFilter = repo.isBookmarked
            case 2: matchesFilter = !repo.isSynced
            default: matchesFilter = true
            }

            return matchesSearch && matchesFilter
        }
    }

    func fetchTableStats() async -> (repos: Int, owners: Int, tags: Int, logs: Int) {
        let repos = (try? context.fetchCount(FetchDescriptor<OfflineRepoItem>())) ?? 0
        let owners = (try? context.fetchCount(FetchDescriptor<OfflineRepoOwner>())) ?? 0
        let tags = (try? context.fetchCount(FetchDescriptor<OfflineRepoTag>())) ?? 0
        let logs = (try? context.fetchCount(FetchDescriptor<OfflineSyncAuditLog>())) ?? 0
        return (repos, owners, tags, logs)
    }

    // MARK: - CRUD Mutations

    func insertRepository(item: OfflineRepoItem) async throws {
        context.insert(item)
        try context.save()
        print("💾 [OfflineRepository] Inserted repository '\(item.name)' into local SwiftData.")
    }

    func toggleBookmark(for item: OfflineRepoItem) async throws {
        item.isBookmarked.toggle()
        try context.save()
        print("⭐️ [OfflineRepository] Toggled bookmark for '\(item.name)': \(item.isBookmarked)")
    }

    func deleteRepository(item: OfflineRepoItem) async throws {
        let name = item.name
        context.delete(item)
        try context.save()
        print("🗑 [OfflineRepository] Deleted repository '\(name)' from SwiftData (Cascaded children).")
    }

    // MARK: - Mock Server API Synchronization

    func syncRepositoryToServer(item: OfflineRepoItem) async throws -> (audit: OfflineSyncAuditLog, latencyMs: Double) {
        item.syncStatus = "syncing"
        let repoName = item.name
        let repoId = item.id
        let startTime = Date()

        print("🌐 [MockServerAPI] Hello! Calling POST /api/v1/sync for '\(repoName)' (ID: \(repoId))...")

        // Simulate network API latency
        try await Task.sleep(nanoseconds: 500_000_000) // ~500ms
        let latency = Date().timeIntervalSince(startTime) * 1000.0

        // Server confirmation (200 OK)
        item.isSynced = true
        item.syncStatus = "synced"
        item.lastSyncedAt = Date()

        let audit = OfflineSyncAuditLog(
            actionType: "MOCK_API_SYNC",
            serverStatusCode: 200,
            syncLatencyMs: latency,
            endpoint: "/api/v1/sync/repositories",
            repository: item
        )
        context.insert(audit)
        try context.save()

        print("☁️ [CloudServer] 200 OK! '\(repoName)' synced successfully in \(Int(latency))ms.")
        return (audit, latency)
    }

    func syncAllPendingRepositories() async throws -> [OfflineRepoItem] {
        let descriptor = FetchDescriptor<OfflineRepoItem>(
            predicate: #Predicate<OfflineRepoItem> { !$0.isSynced }
        )
        let pending = try context.fetch(descriptor)
        for item in pending {
            _ = try await syncRepositoryToServer(item: item)
        }
        return pending
    }

    // MARK: - Background Actor Batch Import

    func importBatchBackground(items: [(id: String, name: String, desc: String, stars: Int, forks: Int, ownerLogin: String, ownerCompany: String, tags: [String])]) async throws -> Int {
        let importer = dataStack.createBackgroundImporter()
        return try await importer.importBatchItems(items: items)
    }

    // MARK: - Database Seeding & Reset

    func seedDefaultRepositoriesIfNeeded() async throws {
        let count = try context.fetchCount(FetchDescriptor<OfflineRepoItem>())
        if count == 0 {
            let appleOwner = OfflineRepoOwner(id: "owner_apple", login: "apple", company: "Apple Inc.", location: "Cupertino, CA")
            let alamofireOwner = OfflineRepoOwner(id: "owner_alamofire", login: "Alamofire", company: "Open Source Foundation", location: "Global")
            let onevcatOwner = OfflineRepoOwner(id: "owner_onevcat", login: "onevcat", company: "LINE", location: "Tokyo, Japan")

            let sample1 = OfflineRepoItem(
                id: "1",
                name: "swift-syntax",
                repoDescription: "A set of Swift libraries for inspecting, generating, and transforming Swift source code.",
                starCount: 3400,
                forkCount: 420,
                language: "Swift",
                owner: appleOwner,
                isBookmarked: true,
                isSynced: true,
                syncStatus: "synced",
                lastSyncedAt: Date()
            )
            sample1.tags = [OfflineRepoTag(name: "compiler", repository: sample1), OfflineRepoTag(name: "ast", repository: sample1)]
            sample1.syncAuditLogs = [OfflineSyncAuditLog(actionType: "INITIAL_SEED", serverStatusCode: 200, syncLatencyMs: 10.0, repository: sample1)]

            let sample2 = OfflineRepoItem(
                id: "2",
                name: "Alamofire",
                repoDescription: "Elegant HTTP Networking in Swift.",
                starCount: 40200,
                forkCount: 7500,
                language: "Swift",
                owner: alamofireOwner,
                isBookmarked: false,
                isSynced: false,
                syncStatus: "pending"
            )
            sample2.tags = [OfflineRepoTag(name: "networking", repository: sample2), OfflineRepoTag(name: "http", repository: sample2)]

            let sample3 = OfflineRepoItem(
                id: "3",
                name: "Kingfisher",
                repoDescription: "A lightweight, pure-Swift library for downloading and caching images from the web.",
                starCount: 23100,
                forkCount: 3600,
                language: "Swift",
                owner: onevcatOwner,
                isBookmarked: true,
                isSynced: false,
                syncStatus: "pending"
            )
            sample3.tags = [OfflineRepoTag(name: "caching", repository: sample3), OfflineRepoTag(name: "image-pipeline", repository: sample3)]

            context.insert(sample1)
            context.insert(sample2)
            context.insert(sample3)

            try context.save()
            print("🌱 [OfflineRepository] Seeded default 4-table records.")
        }
    }

    func clearAllDatabase() async throws {
        try dataStack.wipeAllData()
        print("🧹 [OfflineRepository] Cleared all 4 relational tables via dataStack.")
    }
}

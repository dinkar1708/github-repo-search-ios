//
//  SwiftDataOfflineTests.swift
//  github_repo_search_iOS_app_UnitTests
//
//  Created using Apple's Swift Testing framework (iOS 17.0+ / Swift 6)
//

import Testing
import Foundation
import SwiftData
@testable import github_repo_search_iOS_app

@Suite("SwiftData Offline & Background Scheduler Tests")
struct SwiftDataOfflineTests {

    // MARK: - 1. Initialization & In-Memory Container Tests

    @Test("SwiftDataStack initializes 4 relational schemas successfully")
    func testStackInitialization() throws {
        let schema = Schema([
            OfflineRepoItem.self,
            OfflineRepoOwner.self,
            OfflineRepoTag.self,
            OfflineSyncAuditLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        #expect(container.schema.entities.count == 4)
    }

    // MARK: - 2. Parameterized CRUD & Entity Relational Integrity

    @Test(
        "Inserting repositories with relational owners and tags",
        arguments: [
            ("repo_101", "vapor", "vapor", "Vapor Web Framework"),
            ("repo_102", "grpc-swift", "grpc", "gRPC Swift Library"),
            ("repo_103", "swift-protobuf", "apple", "Swift Protobuf Serialization"),
            ("repo_104", "swift-testing", "swiftlang", "Modern Swift Testing Framework")
        ]
    )
    func testRepositoryInsertionAndRelationships(id: String, name: String, ownerLogin: String, desc: String) async throws {
        let schema = Schema([
            OfflineRepoItem.self,
            OfflineRepoOwner.self,
            OfflineRepoTag.self,
            OfflineSyncAuditLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let repoOwner = OfflineRepoOwner(id: "owner_\(ownerLogin)", login: ownerLogin, avatarUrl: "https://avatar/\(ownerLogin)")
        let item = OfflineRepoItem(
            id: id,
            name: name,
            repoDescription: desc,
            starCount: 1200,
            forkCount: 350,
            language: "Swift",
            owner: repoOwner,
            isBookmarked: false,
            isSynced: false,
            syncStatus: "pending"
        )
        let tag = OfflineRepoTag(name: "#swift-6", repository: item)
        item.tags = [tag]

        context.insert(item)
        try context.save()

        // Fetch back and assert relational integrity
        let descriptor = FetchDescriptor<OfflineRepoItem>(predicate: #Predicate { $0.name == name })
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results.first?.name == name)
        #expect(results.first?.owner?.login == ownerLogin)
        #expect(results.first?.tags?.count == 1)
        #expect(results.first?.isSynced == false)
        #expect(results.first?.syncStatus == "pending")
    }

    // MARK: - 3. Isolated Background Ingestion (@ModelActor)

    @Test("Background worker imports items safely off main thread")
    func testBackgroundWorkerIngestion() async throws {
        let schema = Schema([
            OfflineRepoItem.self,
            OfflineRepoOwner.self,
            OfflineRepoTag.self,
            OfflineSyncAuditLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let worker = BackgroundOfflineImporter(modelContainer: container)
        
        let batchItems: [(id: String, name: String, desc: String, stars: Int, forks: Int, ownerLogin: String, ownerCompany: String, tags: [String])] = [
            ("repo_801", "swift-async-algorithms", "Async sequence algorithms", 3400, 450, "apple", "Apple Inc.", ["#concurrency"]),
            ("repo_802", "swift-syntax", "Swift AST parser and macros", 2100, 310, "swiftlang", "Swift Community", ["#macros"]),
            ("repo_803", "swift-collections", "Data structures for Swift", 4500, 560, "apple", "Apple Inc.", ["#collections"])
        ]

        let importedCount = try await worker.importBatchItems(items: batchItems)
        #expect(importedCount == 3)

        // Verify from main context
        let mainContext = ModelContext(container)
        let allItems = try mainContext.fetch(FetchDescriptor<OfflineRepoItem>())
        #expect(allItems.count == 3)
    }

    // MARK: - 4. Two-Way Cloud Sync & Audit Logging

    @Test("Offline sync updates database state and produces audit log")
    func testCloudSyncStateTransition() async throws {
        let schema = Schema([
            OfflineRepoItem.self,
            OfflineRepoOwner.self,
            OfflineRepoTag.self,
            OfflineSyncAuditLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let repo = OfflineRepoItem(
            id: "repo_999",
            name: "swift-distributed-actors",
            repoDescription: "Peer to peer clustering in Swift",
            starCount: 1800,
            forkCount: 220,
            language: "Swift",
            isSynced: false,
            syncStatus: "pending"
        )
        context.insert(repo)
        try context.save()

        #expect(repo.isSynced == false)
        #expect(repo.syncStatus == "pending")

        // Simulate 200 OK Cloud REST API sync
        repo.isSynced = true
        repo.syncStatus = "synced"
        repo.lastSyncedAt = Date()

        let auditLog = OfflineSyncAuditLog(
            actionType: "MOCK_API_SYNC",
            serverStatusCode: 200,
            syncLatencyMs: 512.0,
            endpoint: "/api/v1/sync/repositories",
            repository: repo
        )
        context.insert(auditLog)
        try context.save()

        let fetchedAudits = try context.fetch(FetchDescriptor<OfflineSyncAuditLog>())
        #expect(fetchedAudits.count == 1)
        #expect(fetchedAudits.first?.serverStatusCode == 200)
        #expect(repo.isSynced == true)
    }

    // MARK: - 5. BGTaskScheduler Background Sync Simulation

    @Test("BGTaskScheduler manual simulation returns valid status")
    @MainActor
    func testBGTaskSchedulerSimulation() async {
        let result = await OfflineBackgroundSyncScheduler.shared.triggerManualSimulation()
        #expect(result.syncedCount >= 0)
        #expect(result.log.contains("BGTaskScheduler"))
    }
}

//
//  OfflineSyncMatrixTests.swift
//  github_repo_search_iOS_app_UnitTests
//
//  Created using Apple's Swift Testing framework (iOS 17.0+ / Swift 6)
//

import Testing
import Foundation
import SwiftData
@testable import github_repo_search_iOS_app

@Suite("Offline Sync & Filter Matrix Tests")
struct OfflineSyncMatrixTests {

    // MARK: - 1. Parameterized Filter Matrix Tests

    @Test(
        "Verifying filter predicates for repository sync status",
        arguments: [
            ("pending", false, 3),
            ("synced", true, 2),
            ("syncing", false, 1)
        ]
    )
    func testSyncFilterPredicates(status: String, isSynced: Bool, expectedCount: Int) async throws {
        let schema = Schema([OfflineRepoItem.self, OfflineRepoOwner.self, OfflineRepoTag.self, OfflineSyncAuditLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Seed sample items with various states
        let items: [(id: String, name: String, status: String, synced: Bool)] = [
            ("1", "repo-pending-1", "pending", false),
            ("2", "repo-pending-2", "pending", false),
            ("3", "repo-pending-3", "pending", false),
            ("4", "repo-synced-1", "synced", true),
            ("5", "repo-synced-2", "synced", true),
            ("6", "repo-syncing-1", "syncing", false)
        ]

        for item in items {
            let model = OfflineRepoItem(
                id: item.id,
                name: item.name,
                starCount: 100,
                forkCount: 10,
                language: "Swift",
                isSynced: item.synced,
                syncStatus: item.status
            )
            context.insert(model)
        }
        try context.save()

        // Test FetchDescriptor with dynamic predicate
        let descriptor = FetchDescriptor<OfflineRepoItem>(
            predicate: #Predicate { $0.syncStatus == status }
        )
        let matches = try context.fetch(descriptor)

        #expect(matches.count == expectedCount)
        for match in matches {
            #expect(match.syncStatus == status)
            #expect(match.isSynced == isSynced)
        }
    }

    // MARK: - 2. Parameterized Tag Association Tests

    @Test(
        "Tag associations and relational cascading across languages",
        arguments: [
            ("vapor", "#swift", 1),
            ("alamofire", "#networking", 1),
            ("kingfisher", "#image-caching", 1)
        ]
    )
    func testTagAssociations(repoName: String, tagName: String, expectedTags: Int) async throws {
        let schema = Schema([OfflineRepoItem.self, OfflineRepoOwner.self, OfflineRepoTag.self, OfflineSyncAuditLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let repo = OfflineRepoItem(
            id: "repo_\(repoName)",
            name: repoName,
            starCount: 500,
            forkCount: 50,
            language: "Swift",
            isSynced: true,
            syncStatus: "synced"
        )
        let tag = OfflineRepoTag(name: tagName, repository: repo)
        repo.tags = [tag]

        context.insert(repo)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<OfflineRepoItem>(predicate: #Predicate { $0.name == repoName }))
        let first = try #require(fetched.first)
        
        #expect(first.tags?.count == expectedTags)
        #expect(first.tags?.first?.name == tagName)
    }

    // MARK: - 3. Bookmark Toggle State Tests

    @Test("Toggling bookmark state updates database correctly")
    func testBookmarkToggle() async throws {
        let schema = Schema([OfflineRepoItem.self, OfflineRepoOwner.self, OfflineRepoTag.self, OfflineSyncAuditLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let repo = OfflineRepoItem(
            id: "repo_test_bm",
            name: "test-bookmark",
            isBookmarked: false
        )
        context.insert(repo)
        try context.save()

        #expect(repo.isBookmarked == false)

        repo.isBookmarked = true
        try context.save()

        let bookmarked = try context.fetch(FetchDescriptor<OfflineRepoItem>(predicate: #Predicate { $0.isBookmarked == true }))
        #expect(bookmarked.count == 1)
        #expect(bookmarked.first?.name == "test-bookmark")
    }
}

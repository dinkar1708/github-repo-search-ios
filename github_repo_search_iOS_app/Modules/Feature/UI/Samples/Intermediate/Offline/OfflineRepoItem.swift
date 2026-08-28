//
//  OfflineRepoItem.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/28.
//

import Foundation
import SwiftData

// MARK: - 1. TABLE: Repositories (OfflineRepoItem)

/// Primary Relational Table: Offline Repositories
@Model
final class OfflineRepoItem {
    @Attribute(.unique) var id: String
    var name: String
    var repoDescription: String
    var starCount: Int
    var forkCount: Int
    var language: String
    var isBookmarked: Bool
    var isSynced: Bool
    var syncStatus: String // "synced", "pending", "syncing", "failed"
    var lastSyncedAt: Date?
    var cachedAt: Date

    // 1-to-1 / Many-to-1 Relationship -> Owner Table
    @Relationship(deleteRule: .nullify)
    var owner: OfflineRepoOwner?

    // 1-to-Many Relationship -> Tags Table (Cascade on delete)
    @Relationship(deleteRule: .cascade, inverse: \OfflineRepoTag.repository)
    var tags: [OfflineRepoTag]? = []

    // 1-to-Many Relationship -> Sync Audit Log Table (Cascade on delete)
    @Relationship(deleteRule: .cascade, inverse: \OfflineSyncAuditLog.repository)
    var syncAuditLogs: [OfflineSyncAuditLog]? = []

    init(
        id: String,
        name: String,
        repoDescription: String = "",
        starCount: Int = 0,
        forkCount: Int = 0,
        language: String = "Swift",
        owner: OfflineRepoOwner? = nil,
        isBookmarked: Bool = false,
        isSynced: Bool = false,
        syncStatus: String = "pending",
        lastSyncedAt: Date? = nil,
        cachedAt: Date = Date(),
        tags: [OfflineRepoTag] = [],
        syncAuditLogs: [OfflineSyncAuditLog] = []
    ) {
        self.id = id
        self.name = name
        self.repoDescription = repoDescription
        self.starCount = starCount
        self.forkCount = forkCount
        self.language = language
        self.owner = owner
        self.isBookmarked = isBookmarked
        self.isSynced = isSynced
        self.syncStatus = syncStatus
        self.lastSyncedAt = lastSyncedAt
        self.cachedAt = cachedAt
        self.tags = tags
        self.syncAuditLogs = syncAuditLogs
    }
}

// MARK: - 2. TABLE: Repository Owners (OfflineRepoOwner)

/// Normalized Relational Table: Repository Owners / Organizations
@Model
final class OfflineRepoOwner {
    @Attribute(.unique) var id: String
    var login: String
    var avatarUrl: String
    var company: String?
    var location: String?

    // Inverse Relationship to Repositories
    @Relationship(inverse: \OfflineRepoItem.owner)
    var repositories: [OfflineRepoItem]? = []

    init(
        id: String = UUID().uuidString,
        login: String,
        avatarUrl: String = "",
        company: String? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.login = login
        self.avatarUrl = avatarUrl
        self.company = company
        self.location = location
    }
}

// MARK: - 3. TABLE: Repository Tags / Topics (OfflineRepoTag)

/// Normalized Relational Table: Repository Topics & Keyword Tags
@Model
final class OfflineRepoTag {
    @Attribute(.unique) var id: String
    var name: String

    // Foreign key link to parent Repository
    var repository: OfflineRepoItem?

    init(id: String = UUID().uuidString, name: String, repository: OfflineRepoItem? = nil) {
        self.id = id
        self.name = name
        self.repository = repository
    }
}

// MARK: - 4. TABLE: Sync Audit & Telemetry Logs (OfflineSyncAuditLog)

/// Normalized Relational Table: Transactional Sync Audit Trail
@Model
final class OfflineSyncAuditLog {
    @Attribute(.unique) var id: String
    var timestamp: Date
    var actionType: String // e.g. "LOCAL_INSERT", "MOCK_API_SYNC", "STATUS_CHANGE"
    var serverStatusCode: Int // 200, 201, 500, etc.
    var syncLatencyMs: Double
    var endpoint: String

    // Foreign key link to parent Repository
    var repository: OfflineRepoItem?

    init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        actionType: String,
        serverStatusCode: Int = 200,
        syncLatencyMs: Double = 0.0,
        endpoint: String = "/api/v1/sync/repositories",
        repository: OfflineRepoItem? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.actionType = actionType
        self.serverStatusCode = serverStatusCode
        self.syncLatencyMs = syncLatencyMs
        self.endpoint = endpoint
        self.repository = repository
    }
}

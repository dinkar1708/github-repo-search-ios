//
//  SwiftDataOfflineStorageView.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2026/08/28.
//

import SwiftUI
import Observation
import SwiftData

/// Interactive MVVM Sample View showcasing Swift 6 @Observable, Multi-Table Normalized SwiftData Schema, and Mock Cloud Server Sync
public struct SwiftDataOfflineStorageView: View {
    @State private var viewModel = SwiftDataOfflineViewModel()

    public init() {}

    public var body: some View {
        @Bindable var boundViewModel = viewModel

        ScrollView {
            VStack(spacing: 16) {
                // Header Status & Sync Toggle Card
                OfflineHeaderSyncCard(
                    totalCount: viewModel.repositories.count,
                    syncedCount: viewModel.syncedCount,
                    pendingCount: viewModel.pendingSyncCount,
                    autoSyncEnabled: $boundViewModel.autoSyncEnabled,
                    isSyncing: viewModel.isSyncing,
                    onSyncAll: {
                        Task { await viewModel.syncAllPending() }
                    }
                )

                // Multi-Table Schema Statistics Card
                OfflineMultiTableStatsCard(
                    repoCount: viewModel.tableStats.repos,
                    ownerCount: viewModel.tableStats.owners,
                    tagCount: viewModel.tableStats.tags,
                    logCount: viewModel.tableStats.logs
                )

                // Actions Control Card
                OfflineActionsCard(
                    isImporting: viewModel.isImporting,
                    isSyncing: viewModel.isSyncing,
                    onAddSingle: { viewModel.addSampleRepository() },
                    onImportBatchBackground: { viewModel.importBatchBackground() },
                    onSimulateBGTask: { viewModel.simulateBGTaskSchedulerRefresh() },
                    onSeedDefaults: { viewModel.seedDefaults() },
                    onClearAll: { viewModel.clearAll() }
                )

                // Filter & Search Bar
                OfflineFilterBar(
                    searchText: $boundViewModel.searchText,
                    selectedFilter: $boundViewModel.selectedFilter,
                    pendingCount: viewModel.pendingSyncCount,
                    filteredCount: viewModel.repositories.count
                )

                // Live Repositories List
                if viewModel.repositories.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Repositories Found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Tap '+ Add Repo' or '⚡️ ModelActor (BG)' to insert multi-table data into SwiftData.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.repositories) { repo in
                            OfflineRepoRowCard(
                                repo: repo,
                                onToggleBookmark: {
                                    viewModel.toggleBookmark(repo: repo)
                                },
                                onSyncSingle: {
                                    Task { await viewModel.syncSingle(repo: repo) }
                                },
                                onDelete: {
                                    viewModel.deleteRepository(repo: repo)
                                }
                            )
                        }
                    }
                }

                // Live Event Log Card (Mock Server API Stream)
                LifecycleEventLogCard(
                    logs: viewModel.recentLogs,
                    onClear: { viewModel.clearAll() }
                )

                // Architecture Guide Card
                OfflineArchitectureGuideCard()
            }
            .padding()
        }
        .navigationTitle("Swift 6 SwiftData & Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }
}

// MARK: - Subviews & UI Components

struct OfflineHeaderSyncCard: View {
    let totalCount: Int
    let syncedCount: Int
    let pendingCount: Int
    @Binding var autoSyncEnabled: Bool
    let isSyncing: Bool
    let onSyncAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cylinder.split.1x2.fill")
                    .font(.title)
                    .foregroundColor(.indigo)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Swift 6 Multi-Table Engine")
                        .font(.headline)
                    Text("@Observable MVVM + Structured Concurrency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle(isOn: $autoSyncEnabled) {
                    Text("Auto-Sync")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .toggleStyle(.button)
                .tint(autoSyncEnabled ? .green : .secondary)
            }

            Divider()

            HStack {
                Label("Repos: \(totalCount)", systemImage: "internaldrive.fill")
                    .font(.caption)

                Spacer()

                Label("Synced: \(syncedCount)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)

                Spacer()

                Label("Pending: \(pendingCount)", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(pendingCount > 0 ? .orange : .secondary)
            }

            if pendingCount > 0 {
                Button(action: onSyncAll) {
                    HStack {
                        if isSyncing {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "icloud.and.arrow.up.fill")
                        }
                        Text(isSyncing ? "Syncing to Cloud Server..." : "Sync \(pendingCount) Pending Repos to Server API")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isSyncing)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct OfflineMultiTableStatsCard: View {
    let repoCount: Int
    let ownerCount: Int
    let tagCount: Int
    let logCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "tablecells.badge.ellipsis")
                    .foregroundColor(.purple)
                Text("4 Normalized Relational Tables")
                    .font(.headline)
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                TableStatItem(name: "Table 1: Repositories", model: "OfflineRepoItem", count: repoCount, icon: "folder.fill", color: .blue)
                TableStatItem(name: "Table 2: Owners", model: "OfflineRepoOwner", count: ownerCount, icon: "person.2.fill", color: .green)
                TableStatItem(name: "Table 3: Topic Tags", model: "OfflineRepoTag", count: tagCount, icon: "tag.fill", color: .indigo)
                TableStatItem(name: "Table 4: Audit Logs", model: "OfflineSyncAuditLog", count: logCount, icon: "doc.text.fill", color: .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TableStatItem: View {
    let name: String
    let model: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.bold)
                Text("\(count) rows (SQLite)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct OfflineActionsCard: View {
    let isImporting: Bool
    let isSyncing: Bool
    let onAddSingle: () -> Void
    let onImportBatchBackground: () -> Void
    let onSimulateBGTask: () -> Void
    let onSeedDefaults: () -> Void
    let onClearAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Database & Concurrency Actions")
                .font(.headline)

            HStack(spacing: 8) {
                Button(action: onAddSingle) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("+ Add Repo")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button(action: onImportBatchBackground) {
                    HStack(spacing: 4) {
                        if isImporting {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Image(systemName: "bolt.fill")
                        }
                        Text("⚡️ ModelActor (BG)")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(.purple)

                Spacer()

                Button("Seed", action: onSeedDefaults)
                    .font(.caption)
                    .buttonStyle(.bordered)

                Button("Clear", action: onClearAll)
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.red)
            }

            // OS-Level BGTaskScheduler Trigger (iOS WorkManager simulation)
            Button(action: onSimulateBGTask) {
                HStack(spacing: 6) {
                    if isSyncing {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "moon.stars.fill")
                    }
                    Text(isSyncing ? "Running Background Sync via Scheduler..." : "🌙 Invoke BGTaskScheduler (Background Sync)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.indigo.opacity(0.15))
                .foregroundColor(.indigo)
                .cornerRadius(8)
            }
            .disabled(isSyncing)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct OfflineFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: Int
    let pendingCount: Int
    let filteredCount: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search repositories, authors...", text: $searchText)
                    .font(.subheadline)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)

            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(0)
                Text("⭐️ Bookmarked").tag(1)
                Text("⏳ Pending (\(pendingCount))").tag(2)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct OfflineRepoRowCard: View {
    let repo: OfflineRepoItem
    let onToggleBookmark: () -> Void
    let onSyncSingle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(repo.name)
                        .font(.subheadline)
                        .fontWeight(.bold)

                    if let owner = repo.owner {
                        Text("by \(owner.login) • \(owner.company ?? "Individual") • \(repo.language)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(repo.language)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 10) {
                    Label("\(repo.starCount)", systemImage: "star.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)

                    Button(action: onToggleBookmark) {
                        Image(systemName: repo.isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(repo.isBookmarked ? .indigo : .secondary)
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }

            if !repo.repoDescription.isEmpty {
                Text(repo.repoDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Sync Status, Audit Log Count & Tag Row
            HStack {
                if let tags = repo.tags, !tags.isEmpty {
                    ForEach(tags.prefix(2)) { tag in
                        Text("#\(tag.name)")
                            .font(.system(.caption2, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.12))
                            .foregroundColor(.indigo)
                            .cornerRadius(4)
                    }
                }

                if let logCount = repo.syncAuditLogs?.count, logCount > 0 {
                    Text("📜 \(logCount) logs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if repo.isSynced {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Synced")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                } else {
                    Button(action: onSyncSingle) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync to API")
                        }
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct OfflineArchitectureGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modern Swift 6 Concurrency & Observation")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                PrincipleBullet(title: "1. Swift 6 @Observable Macro", text: "Zero Combine boilerplate: standard properties are tracked with fine-grained per-property UI invalidation.")
                PrincipleBullet(title: "2. @ModelActor Concurrency Isolation", text: "Background batch operations run on an isolated Swift 6 Actor with its own dedicated ModelContext.")
                PrincipleBullet(title: "3. MainActor UI State Protection", text: "ViewModel runs on @MainActor, ensuring complete thread-safety for all view interactions.")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

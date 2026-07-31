//
//  SearchItemDetailsView.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/16.
//

import SwiftUI

/**
 Show comprehensive details of search item with modern iOS design
 */
struct SearchItemDetailsView: View {
    var searchItem: SearchItem
    @Environment(\.openURL) var openURL
    @State private var favoritesManager = FavoritesManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Section
                heroSection

                // Statistics Cards
                statsSection

                // Repository Info
                repositoryInfoSection

                // Owner Info
                ownerInfoSection

                // Action Buttons
                actionButtonsSection

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(searchItem.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: favoritesManager.isFavoriteRepository(repositoryId: searchItem.id) ? "star.fill" : "star")
                        .foregroundColor(favoritesManager.isFavoriteRepository(repositoryId: searchItem.id) ? .yellow : .gray)
                }
            }
        }
    }

    private func toggleFavorite() {
        if favoritesManager.isFavoriteRepository(repositoryId: searchItem.id) {
            favoritesManager.removeFavoriteRepository(repositoryId: searchItem.id)
        } else {
            favoritesManager.addFavoriteRepository(repository: searchItem)
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Owner Avatar
            AsyncImage(url: URL(string: searchItem.owner.avatarURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(radius: 5)
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            // Repository name
            Text(searchItem.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Full name
            Text(searchItem.fullName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Description
            if let description = searchItem.itemDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Language tag
            if let language = searchItem.language {
                HStack {
                    Circle()
                        .fill(Color.languageColor(for: language))
                        .frame(width: 12, height: 12)
                    Text(language)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Statistics Section
    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(icon: "star.fill", title: "Stars", value: "\(searchItem.stargazersCount)", color: .yellow)
            StatCard(icon: "tuningfork", title: "Forks", value: "\(searchItem.forksCount)", color: .blue)
            StatCard(icon: "eye.fill", title: "Watchers", value: "\(searchItem.watchersCount)", color: .green)
            StatCard(icon: "exclamationmark.triangle.fill", title: "Issues", value: "\(searchItem.openIssuesCount)", color: .red)
        }
    }

    // MARK: - Repository Info Section
    private var repositoryInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repository Information")
                .font(.headline)
                .fontWeight(.bold)

            InfoRow(icon: "person.fill", title: "Owner", value: searchItem.owner.login)
            InfoRow(icon: "link", title: "Type", value: searchItem.owner.type)
            InfoRow(icon: "folder.fill", title: "Default Branch", value: searchItem.defaultBranch)

            if let homepage = searchItem.homepage, !homepage.isEmpty {
                InfoRow(icon: "house.fill", title: "Homepage", value: homepage)
            }

            if let license = searchItem.license {
                InfoRow(icon: "doc.text.fill", title: "License", value: license.name)
            }

            InfoRow(icon: "arrow.down.circle.fill", title: "Size", value: "\(searchItem.size) KB")

            if let createdAt = searchItem.createdAt {
                InfoRow(icon: "calendar", title: "Created", value: formatDate(createdAt))
            }

            if let updatedAt = searchItem.updatedAt {
                InfoRow(icon: "clock.fill", title: "Updated", value: formatDate(updatedAt))
            }

            // Features
            HStack(spacing: 12) {
                if searchItem.hasIssues {
                    FeatureBadge(text: "Issues", icon: "exclamationmark.circle.fill")
                }
                if searchItem.hasWiki {
                    FeatureBadge(text: "Wiki", icon: "book.fill")
                }
                if searchItem.hasPages {
                    FeatureBadge(text: "Pages", icon: "doc.fill")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Owner Info Section
    private var ownerInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Owner Details")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                AsyncImage(url: URL(string: searchItem.owner.avatarURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(searchItem.owner.login)
                        .font(.headline)
                    Text(searchItem.owner.type)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if searchItem.owner.siteAdmin {
                        Text("Site Admin")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                if let url = URL(string: searchItem.htmlURL) {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.up.forward.square.fill")
                    Text("Open in GitHub")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            Button(action: {
                UIPasteboard.general.string = searchItem.cloneURL
            }) {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                    Text("Copy Clone URL")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Functions
    // Removed: languageColor() now centralized in Color+Extensions

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
}

struct FeatureBadge: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
        .foregroundColor(.blue)
    }
}

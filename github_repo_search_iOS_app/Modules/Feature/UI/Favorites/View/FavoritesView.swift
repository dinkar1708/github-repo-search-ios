//
//  FavoritesView.swift
//  github_repo_search_iOS_app
//
//  Created for Favorites feature (Feature 3.0)
//

import SwiftUI

enum FavoriteType: String, CaseIterable {
    case users = "Users"
    case repositories = "Repositories"
}

struct FavoritesView: View {
    @State private var favoritesManager = FavoritesManager.shared
    @State private var showingClearAlert = false
    @State private var selectedType: FavoriteType = .users

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Favorite Type", selection: $selectedType) {
                    ForEach(FavoriteType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color(UIColor.systemBackground))
                .accessibilityLabel("Favorite type selector")
                .accessibilityValue(selectedType.rawValue)

                // Content
                Group {
                    if selectedType == .users {
                        if favoritesManager.favoriteUsers.isEmpty {
                            EmptyFavoritesView(type: .users)
                        } else {
                            List {
                                ForEach(favoritesManager.favoriteUsers) { favorite in
                                    NavigationLink(destination: UserProfileView(username: favorite.login)) {
                                        FavoriteUserCell(favorite: favorite)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("User: \(favorite.name ?? favorite.login), \(favorite.followers) followers")
                                    .accessibilityHint("Double tap to view profile. Swipe left to delete")
                                }
                                .onDelete(perform: deleteUserFavorites)
                            }
                            .listStyle(.plain)
                        }
                    } else {
                        if favoritesManager.favoriteRepositories.isEmpty {
                            EmptyFavoritesView(type: .repositories)
                        } else {
                            List {
                                ForEach(favoritesManager.favoriteRepositories) { favorite in
                                    NavigationLink(destination: SearchItemDetailsView(searchItem: favorite.toSearchItem())) {
                                        FavoriteRepositoryCell(favorite: favorite)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Repository: \(favorite.name), by \(favorite.ownerLogin), \(favorite.stargazersCount) stars")
                                    .accessibilityHint("Double tap to view details. Swipe left to delete")
                                }
                                .onDelete(perform: deleteRepositoryFavorites)
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if (selectedType == .users && !favoritesManager.favoriteUsers.isEmpty) ||
                   (selectedType == .repositories && !favoritesManager.favoriteRepositories.isEmpty) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Clear all favorites")
                        .accessibilityHint("Double tap to clear all \(selectedType == .users ? "user" : "repository") favorites")
                    }
                }
            }
            .alert("Clear All Favorites", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    if selectedType == .users {
                        favoritesManager.clearAllUserFavorites()
                    } else {
                        favoritesManager.clearAllRepositoryFavorites()
                    }
                }
            } message: {
                Text("Are you sure you want to remove all favorite \(selectedType == .users ? "users" : "repositories")?")
            }
        }
    }

    private func deleteUserFavorites(at offsets: IndexSet) {
        for index in offsets {
            let favorite = favoritesManager.favoriteUsers[index]
            favoritesManager.removeFavoriteUser(username: favorite.login)
        }
    }

    private func deleteRepositoryFavorites(at offsets: IndexSet) {
        for index in offsets {
            let favorite = favoritesManager.favoriteRepositories[index]
            favoritesManager.removeFavoriteRepository(repositoryId: favorite.id)
        }
    }
}

// MARK: - Favorite User Cell
struct FavoriteUserCell: View {
    let favorite: FavoriteUser

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: favorite.avatarUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(favorite.name ?? favorite.login)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("@\(favorite.login)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let bio = favorite.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption2)
                        Text("\(favorite.publicRepos)")
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption2)
                        Text("\(favorite.followers)")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Favorite Repository Cell
struct FavoriteRepositoryCell: View {
    let favorite: FavoriteRepository

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: favorite.ownerAvatarUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(favorite.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(favorite.ownerLogin)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let description = favorite.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    if let language = favorite.language {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(languageColor(for: language))
                                .frame(width: 8, height: 8)
                            Text(language)
                                .font(.caption)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("\(favorite.stargazersCount)")
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "tuningfork")
                            .font(.caption2)
                        Text("\(favorite.forksCount)")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
        }
        .padding(.vertical, 8)
    }

    private func languageColor(for language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript", "typescript": return .yellow
        case "python": return .blue
        case "java": return .red
        case "kotlin": return .purple
        case "go": return Color(red: 0, green: 0.7, blue: 0.9)
        case "rust": return Color(red: 0.87, green: 0.45, blue: 0.3)
        case "ruby": return .red
        case "php": return Color(red: 0.5, green: 0.4, blue: 0.7)
        default: return .gray
        }
    }
}

// MARK: - Empty Favorites View
struct EmptyFavoritesView: View {
    let type: FavoriteType

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            Text("No Favorites Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Start adding your favorite GitHub \(type == .users ? "users" : "repositories")")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No favorites yet. Start adding your favorite GitHub \(type == .users ? "users" : "repositories")")
    }
}

#Preview {
    FavoritesView()
}

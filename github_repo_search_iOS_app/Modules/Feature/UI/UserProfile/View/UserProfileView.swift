//
//  UserProfileView.swift
//  github_repo_search_iOS_app
//
//  Created for User Profile feature (Feature 1.3)
//

import SwiftUI

struct UserProfileView: View {
    let username: String
    @State private var viewModel = UserProfileViewModel()
    @State private var favoritesManager = FavoritesManager.shared

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                AppProgressView()
                    .padding(.top, 100)
                    .accessibilityLabel("Loading user profile")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    ErrorView(title: error)

                    // Retry button
                    Button(action: {
                        Task {
                            await viewModel.refresh(username: username)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .accessibilityLabel("Retry loading profile")
                    .accessibilityHint("Double tap to retry loading the profile")
                }
                .padding(.top, 100)
                .accessibilityLabel("Error: \(error)")
            } else if let profile = viewModel.userProfile {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderView(profile: profile)

                    // Stats
                    StatsView(profile: profile)

                    // Repositories Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Repositories")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                viewModel.toggleForksFilter()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.showForksOnly ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.showForksOnly ? .blue : .gray)
                                    Text("Forks only")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .accessibilityLabel(viewModel.showForksOnly ? "Showing forks only" : "Show all repositories")
                            .accessibilityHint("Double tap to toggle filter")
                        }
                        .padding(.horizontal)

                        if viewModel.filteredRepositories.isEmpty {
                            Text("No repositories found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .accessibilityLabel("No repositories found")
                        } else {
                            ForEach(viewModel.filteredRepositories) { repo in
                                Button(action: {
                                    openRepository(repo)
                                }) {
                                    UserRepositoryCell(repository: repo)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Repository: \(repo.name), \(repo.stargazersCount) stars, \(repo.language ?? "No language")")
                                .accessibilityHint("Double tap to open in browser")
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let profile = viewModel.userProfile {
                    Button(action: {
                        toggleFavorite(profile: profile)
                    }) {
                        Image(systemName: favoritesManager.isFavoriteUser(username: username) ? "star.fill" : "star")
                            .foregroundColor(favoritesManager.isFavoriteUser(username: username) ? .yellow : .gray)
                    }
                    .accessibilityLabel(favoritesManager.isFavoriteUser(username: username) ? "Remove from favorites" : "Add to favorites")
                    .accessibilityHint("Double tap to toggle favorite")
                }
            }
        }
        .refreshable {
            await viewModel.refresh(username: username)
        }
        .task {
            await viewModel.loadUserProfile(username: username)
        }
    }

    private func toggleFavorite(profile: UserProfile) {
        if favoritesManager.isFavoriteUser(username: username) {
            favoritesManager.removeFavoriteUser(username: username)
        } else {
            favoritesManager.addFavoriteUser(profile: profile)
        }
    }

    // Open repository in browser instead of trying to convert
    private func openRepository(_ repo: UserRepository) {
        if let url = URL(string: repo.htmlUrl) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: profile.avatarUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
            )

            Text(profile.name ?? profile.login)
                .font(.title)
                .fontWeight(.bold)

            Text("@\(profile.login)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let bio = profile.bio {
                Text(bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.primary)
            }

            if let location = profile.location {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(location)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }

            if let company = profile.company {
                HStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                    Text(company)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Stats View
struct StatsView: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 40) {
            StatView(title: "Repos", value: "\(profile.publicRepos)")
            StatView(title: "Followers", value: "\(profile.followers)")
            StatView(title: "Following", value: "\(profile.following)")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - User Repository Cell
struct UserRepositoryCell: View {
    let repository: UserRepository

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(repository.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                if repository.fork {
                    Image(systemName: "tuningfork")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let description = repository.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                if let language = repository.language {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text(language)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 15) {
                    Label("\(repository.stargazersCount)", systemImage: "star")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(repository.forksCount)", systemImage: "tuningfork")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        UserProfileView(username: "octocat")
    }
}

//
//  FavoritesRepository.swift
//  github_repo_search_iOS_app
//
//  Created for favorites data management with secure storage
//

import Foundation
import OSLog

// MARK: - Protocol

protocol FavoritesRepository: Sendable {
    func saveFavoriteUser(_ user: FavoriteUser) async throws
    func removeFavoriteUser(id: Int) async throws
    func getFavoriteUsers() async throws -> [FavoriteUser]
    func isFavoriteUser(id: Int) async -> Bool

    func saveFavoriteRepository(_ repo: FavoriteRepository) async throws
    func removeFavoriteRepository(id: Int) async throws
    func getFavoriteRepositories() async throws -> [FavoriteRepository]
    func isFavoriteRepository(id: Int) async -> Bool
}

// MARK: - Keychain Implementation

final class KeychainFavoritesRepository: FavoritesRepository {
    private let keychain = KeychainManager()
    private let logger = Logger.repository

    private let userFavoritesKey = "favoriteUsers"
    private let repoFavoritesKey = "favoriteRepositories"

    // MARK: - Users

    func saveFavoriteUser(_ user: FavoriteUser) async throws {
        var users = try await getFavoriteUsers()

        // Remove if already exists (update)
        users.removeAll { $0.id == user.id }

        // Add new user
        users.append(user)

        // Save to keychain
        try keychain.save(users, for: userFavoritesKey)
        logger.info("Saved favorite user: \(user.login)")
    }

    func removeFavoriteUser(id: Int) async throws {
        var users = try await getFavoriteUsers()
        users.removeAll { $0.id == id }
        try keychain.save(users, for: userFavoritesKey)
        logger.info("Removed favorite user with id: \(id)")
    }

    func getFavoriteUsers() async throws -> [FavoriteUser] {
        do {
            let users = try keychain.load(for: userFavoritesKey, as: [FavoriteUser].self)
            logger.debug("Loaded \(users.count) favorite users from keychain")
            return users
        } catch KeychainManager.KeychainError.itemNotFound {
            // First time - try migration from UserDefaults
            return try await migrateUsersFromUserDefaults()
        }
    }

    func isFavoriteUser(id: Int) async -> Bool {
        guard let users = try? await getFavoriteUsers() else { return false }
        return users.contains { $0.id == id }
    }

    // MARK: - Repositories

    func saveFavoriteRepository(_ repo: FavoriteRepository) async throws {
        var repos = try await getFavoriteRepositories()

        // Remove if already exists (update)
        repos.removeAll { $0.id == repo.id }

        // Add new repository
        repos.append(repo)

        // Save to keychain
        try keychain.save(repos, for: repoFavoritesKey)
        logger.info("Saved favorite repository: \(repo.name)")
    }

    func removeFavoriteRepository(id: Int) async throws {
        var repos = try await getFavoriteRepositories()
        repos.removeAll { $0.id == id }
        try keychain.save(repos, for: repoFavoritesKey)
        logger.info("Removed favorite repository with id: \(id)")
    }

    func getFavoriteRepositories() async throws -> [FavoriteRepository] {
        do {
            let repos = try keychain.load(for: repoFavoritesKey, as: [FavoriteRepository].self)
            logger.debug("Loaded \(repos.count) favorite repositories from keychain")
            return repos
        } catch KeychainManager.KeychainError.itemNotFound {
            // First time - try migration from UserDefaults
            return try await migrateRepositoriesFromUserDefaults()
        }
    }

    func isFavoriteRepository(id: Int) async -> Bool {
        guard let repos = try? await getFavoriteRepositories() else { return false }
        return repos.contains { $0.id == id }
    }

    // MARK: - Migration from UserDefaults

    private func migrateUsersFromUserDefaults() async throws -> [FavoriteUser] {
        logger.info("Attempting to migrate favorite users from UserDefaults")

        guard let data = UserDefaults.standard.data(forKey: userFavoritesKey),
              let users = try? JSONDecoder().decode([FavoriteUser].self, from: data) else {
            logger.info("No favorite users found in UserDefaults")
            return []
        }

        // Save to keychain
        try keychain.save(users, for: userFavoritesKey)

        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: userFavoritesKey)

        logger.info("Successfully migrated \(users.count) favorite users to keychain")
        return users
    }

    private func migrateRepositoriesFromUserDefaults() async throws -> [FavoriteRepository] {
        logger.info("Attempting to migrate favorite repositories from UserDefaults")

        guard let data = UserDefaults.standard.data(forKey: repoFavoritesKey),
              let repos = try? JSONDecoder().decode([FavoriteRepository].self, from: data) else {
            logger.info("No favorite repositories found in UserDefaults")
            return []
        }

        // Save to keychain
        try keychain.save(repos, for: repoFavoritesKey)

        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: repoFavoritesKey)

        logger.info("Successfully migrated \(repos.count) favorite repositories to keychain")
        return repos
    }
}

// MARK: - Mock Implementation for Tests

final class MockFavoritesRepository: FavoritesRepository {
    var users: [FavoriteUser] = []
    var repositories: [FavoriteRepository] = []

    func saveFavoriteUser(_ user: FavoriteUser) async throws {
        users.removeAll { $0.id == user.id }
        users.append(user)
    }

    func removeFavoriteUser(id: Int) async throws {
        users.removeAll { $0.id == id }
    }

    func getFavoriteUsers() async throws -> [FavoriteUser] {
        return users
    }

    func isFavoriteUser(id: Int) async -> Bool {
        return users.contains { $0.id == id }
    }

    func saveFavoriteRepository(_ repo: FavoriteRepository) async throws {
        repositories.removeAll { $0.id == repo.id }
        repositories.append(repo)
    }

    func removeFavoriteRepository(id: Int) async throws {
        repositories.removeAll { $0.id == id }
    }

    func getFavoriteRepositories() async throws -> [FavoriteRepository] {
        return repositories
    }

    func isFavoriteRepository(id: Int) async -> Bool {
        return repositories.contains { $0.id == id }
    }
}

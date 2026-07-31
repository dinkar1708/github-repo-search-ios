//
//  KeychainManager.swift
//  github_repo_search_iOS_app
//
//  Created for secure keychain storage
//

import Foundation
import Security
import OSLog

/// Secure storage manager using iOS Keychain
final class KeychainManager: Sendable {
    private let logger = Logger.storage

    enum KeychainError: Error, LocalizedError {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
        case deleteFailed(OSStatus)
        case itemNotFound
        case invalidData

        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                return "Failed to save to keychain: \(status)"
            case .loadFailed(let status):
                return "Failed to load from keychain: \(status)"
            case .deleteFailed(let status):
                return "Failed to delete from keychain: \(status)"
            case .itemNotFound:
                return "Item not found in keychain"
            case .invalidData:
                return "Invalid data format"
            }
        }
    }

    // MARK: - Save

    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            logger.error("Failed to save to keychain: \(status)")
            throw KeychainError.saveFailed(status)
        }

        logger.debug("Successfully saved to keychain for key: \(key, privacy: .private)")
    }

    func save<T: Encodable>(_ value: T, for key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try save(data, for: key)
    }

    // MARK: - Load

    func load(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            logger.error("Failed to load from keychain: \(status)")
            throw KeychainError.loadFailed(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        logger.debug("Successfully loaded from keychain for key: \(key, privacy: .private)")
        return data
    }

    func load<T: Decodable>(for key: String, as type: T.Type) throws -> T {
        let data = try load(for: key)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    // MARK: - Delete

    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to delete from keychain: \(status)")
            throw KeychainError.deleteFailed(status)
        }

        logger.debug("Successfully deleted from keychain for key: \(key, privacy: .private)")
    }

    // MARK: - Clear All

    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to clear keychain: \(status)")
            throw KeychainError.deleteFailed(status)
        }

        logger.info("Successfully cleared all keychain items")
    }
}

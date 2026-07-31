//
//  CacheService.swift
//  github_repo_search_iOS_app
//
//  Created for in-memory caching with TTL support
//

import Foundation
import OSLog

// MARK: - Protocol

/// Service for caching data with time-to-live support
protocol CacheService: Sendable {
    func get<T: Decodable>(key: String) -> T?
    func set<T: Encodable>(_ value: T, for key: String, ttl: TimeInterval)
    func remove(key: String)
    func clear()
}

// MARK: - Implementation

final class DefaultCacheService: CacheService, @unchecked Sendable {
    private let cache = NSCache<NSString, CacheEntry>()
    private let logger = Logger.cache

    init() {
        cache.countLimit = 100 // Maximum 100 cached items
        cache.totalCostLimit = 10 * 1024 * 1024 // 10 MB maximum
    }

    func get<T: Decodable>(key: String) -> T? {
        guard let entry = cache.object(forKey: key as NSString) else {
            logger.debug("Cache miss for key: \(key, privacy: .private)")
            return nil
        }

        // Check if expired
        if entry.expiresAt < Date() {
            logger.debug("Cache expired for key: \(key, privacy: .private)")
            cache.removeObject(forKey: key as NSString)
            return nil
        }

        // Decode value
        guard let value = try? JSONDecoder().decode(T.self, from: entry.data) else {
            logger.error("Failed to decode cached value for key: \(key, privacy: .private)")
            cache.removeObject(forKey: key as NSString)
            return nil
        }

        logger.debug("Cache hit for key: \(key, privacy: .private)")
        return value
    }

    func set<T: Encodable>(_ value: T, for key: String, ttl: TimeInterval) {
        guard let data = try? JSONEncoder().encode(value) else {
            logger.error("Failed to encode value for caching: \(key, privacy: .private)")
            return
        }

        let entry = CacheEntry(
            data: data,
            expiresAt: Date().addingTimeInterval(ttl)
        )

        cache.setObject(entry, forKey: key as NSString, cost: data.count)
        logger.debug("Cached value for key: \(key, privacy: .private), TTL: \(ttl)s")
    }

    func remove(key: String) {
        cache.removeObject(forKey: key as NSString)
        logger.debug("Removed cache for key: \(key, privacy: .private)")
    }

    func clear() {
        cache.removeAllObjects()
        logger.info("Cleared all cache")
    }
}

// MARK: - Cache Entry

private final class CacheEntry: NSObject {
    let data: Data
    let expiresAt: Date

    init(data: Data, expiresAt: Date) {
        self.data = data
        self.expiresAt = expiresAt
    }
}

// MARK: - Mock Implementation for Tests

final class MockCacheService: CacheService {
    // Note: Used in tests on @MainActor - thread safety not required
    nonisolated(unsafe) private var storage: [String: Any] = [:]

    func get<T: Decodable>(key: String) -> T? {
        return storage[key] as? T
    }

    func set<T: Encodable>(_ value: T, for key: String, ttl: TimeInterval) {
        storage[key] = value
    }

    func remove(key: String) {
        storage.removeValue(forKey: key)
    }

    func clear() {
        storage.removeAll()
    }
}

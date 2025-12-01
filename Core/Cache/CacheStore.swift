import Foundation
import SwiftData

@Model
final class APICacheEntry {
    @Attribute(.unique) var key: String
    var value: Data
    var timestamp: Date
    
    init(key: String, value: Data, timestamp: Date = .now) {
        self.key = key
        self.value = value
        self.timestamp = timestamp
    }
}

import Foundation
import SwiftData

actor CacheStore {
    private let context: ModelContext
    private let ttl: TimeInterval

    init(context: ModelContext, ttl: TimeInterval) {
        self.context = context
        self.ttl = ttl
        startCleanupLoop()
    }

    // MARK: - Key builder

    func key(_ parts: [String: Any?], method: String) -> String {
        let body = parts
            .sorted { $0.key < $1.key }
            .map { key, value in
                let v: String
                if let s = value as? String {
                    v = s
                } else if let n = value as? CustomStringConvertible {
                    v = n.description
                } else if value == nil {
                    v = "_"
                } else {
                    v = String(describing: value!)
                }
                return "\(key)=\(v)"
            }
            .joined(separator: "|")
        return "\(method)|\(body)"
    }

    // MARK: - Load / Store

    func load<T: Decodable>(_ key: String, as type: T.Type) -> T? {
        let descriptor = FetchDescriptor<APICacheEntry>(predicate: #Predicate { $0.key == key })
        guard let entry = (try? context.fetch(descriptor))?.first else { return nil }

        // TTL check
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            context.delete(entry)
            try? context.save()
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: entry.value)
    }

    func store<T: Encodable>(_ key: String, object: T) {
        let data = try! JSONEncoder().encode(object)

        let descriptor = FetchDescriptor<APICacheEntry>(predicate: #Predicate { $0.key == key })
        if let old = (try? context.fetch(descriptor))?.first {
            old.value = data
            old.timestamp = .now
        } else {
            context.insert(APICacheEntry(key: key, value: data, timestamp: .now))
        }

        try? context.save()
    }

    // MARK: - Invalidation

    func invalidate(prefix: String) {
        let descriptor = FetchDescriptor<APICacheEntry>()
        guard let entries = try? context.fetch(descriptor) else { return }

        for entry in entries where entry.key.hasPrefix(prefix) {
            context.delete(entry)
        }
        try? context.save()
    }

    func invalidateAll() {
        let descriptor = FetchDescriptor<APICacheEntry>()
        guard let entries = try? context.fetch(descriptor) else { return }
        for entry in entries {
            context.delete(entry)
        }
        try? context.save()
    }

    // MARK: - Periodic cleanup

    private func startCleanupLoop() {
        Task.detached { [weak self] in
            guard let self else { return }
            while true {
                try await Task.sleep(for: .seconds(30))  // каждые 30 секунд
                await self.cleanupExpired()
            }
        }
    }

    private func cleanupExpired() {
        let descriptor = FetchDescriptor<APICacheEntry>()
        guard let entries = try? context.fetch(descriptor) else { return }

        let now = Date()
        var changed = false
        for entry in entries {
            if now.timeIntervalSince(entry.timestamp) > ttl {
                context.delete(entry)
                changed = true
            }
        }
        if changed { try? context.save() }
    }
}

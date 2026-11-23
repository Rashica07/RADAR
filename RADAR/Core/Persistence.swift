import Foundation
import OSLog

/// Small JSON-file persistence for user state (library, settings, downloads, imports).
///
/// Each key is one file in Application Support/RADAR. Writes are coalesced and
/// performed on a background queue so rapid changes never block the main thread.
final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    /// Bump when stored shapes change incompatibly. Mirrors the web build's `radar.demo.v1.` prefix.
    static let namespace = "radar.v1"

    let directory: URL
    private let queue = DispatchQueue(label: "radar.persistence", qos: .utility)
    private var pending: [String: Data] = [:]
    private var scheduled = false
    private let lock = NSLock()
    private let log = Logger(subsystem: "app.radar", category: "persistence")

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directory = base.appendingPathComponent("RADAR", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    private func url(for key: String) -> URL {
        directory.appendingPathComponent("\(Self.namespace).\(key).json")
    }

    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = try? Data(contentsOf: url(for: key)) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            log.error("Discarding unreadable \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Coalesced write. The value is encoded immediately on the caller's thread, so the
    /// background write never touches main-actor state.
    func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        lock.lock()
        pending[key] = data
        let needsSchedule = !scheduled
        scheduled = true
        lock.unlock()
        if needsSchedule {
            queue.asyncAfter(deadline: .now() + 0.35) { [weak self] in self?.writePending() }
        }
    }

    func remove(key: String) {
        lock.lock()
        pending[key] = nil
        lock.unlock()
        try? FileManager.default.removeItem(at: url(for: key))
    }

    /// Writes anything still queued, synchronously. Called when the app leaves the foreground.
    func flush() {
        queue.sync { writePending() }
    }

    private func writePending() {
        lock.lock()
        let batch = pending
        pending.removeAll()
        scheduled = false
        lock.unlock()
        for (key, data) in batch {
            do {
                try data.write(to: url(for: key), options: [.atomic])
            } catch {
                log.error("Write failed for \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

import Foundation
import Observation

/// **Simulated** offline downloads for demo catalog tracks.
///
/// No demo provider is connected, so nothing is fetched and no file is written. The
/// progress, rates and sizes are simulated so the download UI can be judged, and every
/// surface that shows them says so. Only the list of "completed" ids is persisted.
@MainActor
@Observable
final class DownloadCenter {
    struct Progress: Equatable, Sendable {
        var pct: Double
        var mb: Double
        var rate: Double
    }

    private static let key = "downloads"
    private let persistence: PersistenceController
    private let catalog: DemoCatalog
    private let toasts: ToastCenter

    private(set) var active: [String: Progress] = [:]
    private(set) var done: [String] { didSet { persistence.save(done, key: Self.key) } }
    private var ticker: Task<Void, Never>?

    init(catalog: DemoCatalog, toasts: ToastCenter, persistence: PersistenceController = .shared) {
        self.catalog = catalog
        self.toasts = toasts
        self.persistence = persistence
        self.done = persistence.load([String].self, key: Self.key) ?? []
    }

    /// Demo size estimate: about 1.4 MB per minute plus 2 MB.
    func sizeMB(_ track: Track) -> Double {
        if let local = track.local { return local.sizeMB }
        return ((track.duration / 60) * 1.4 * 10).rounded() / 10 + 2
    }

    func isDone(_ track: Track) -> Bool { track.download == .downloaded || done.contains(track.id) }
    func isActive(_ id: String) -> Bool { active[id] != nil }

    /// Downloaded catalog tracks (simulated), in catalog order.
    var offlineTracks: [Track] { catalog.tracks.filter(isDone) }

    func start(_ id: String) {
        guard active[id] == nil else { return }
        active[id] = Progress(pct: 0, mb: 0, rate: 0)
        Haptics.play(.light)
        toasts.show("Simulated download started · no file is saved", icon: .download)
        startTicker()
    }

    func cancel(_ id: String) {
        guard active.removeValue(forKey: id) != nil else { return }
        Haptics.play(.warning)
        toasts.show("Download cancelled", icon: .x)
    }

    func remove(_ id: String) {
        done.removeAll { $0 == id }
        Haptics.play(.select)
        toasts.show("Removed from simulated downloads", icon: .trash)
    }

    func resetAll() {
        active = [:]
        done = []
    }

    private func startTicker() {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(110))
                guard let self else { return }
                if !self.tick() { break }
            }
            self?.ticker = nil
        }
    }

    /// Advances every active download. Returns false when nothing is left to do.
    private func tick() -> Bool {
        guard !active.isEmpty else { return false }
        var next: [String: Progress] = [:]
        var finished: [String] = []
        for (id, p) in active {
            guard let track = catalog.track(id) else { continue }
            let step = (0.9 + Double.random(in: 0..<2.4)) * (1 - p.pct / 140)
            let pct = min(100, p.pct + step)
            if pct >= 100 {
                finished.append(id)
            } else {
                let rate = ((2 + Double.random(in: 0..<3.2)) * 10).rounded() / 10
                next[id] = Progress(pct: pct, mb: pct / 100 * sizeMB(track), rate: rate)
            }
        }
        active = next
        if !finished.isEmpty {
            done += finished.filter { !done.contains($0) }
            Haptics.play(.success)
            for id in finished {
                toasts.show("\(catalog.track(id)?.title ?? "Track") · simulated download complete", icon: .check)
            }
        }
        return !active.isEmpty
    }
}

import Foundation

enum RepeatMode: String, Codable, Sendable, CaseIterable {
    case off, all, one
    var cycled: RepeatMode { switch self { case .off: .all; case .all: .one; case .one: .off } }
}

/// The play queue and its rules, with no audio and no UI. Holds track ids; `index` is the one playing now.
struct PlayQueue: Equatable, Sendable {
    private(set) var ids: [String]
    private(set) var index: Int

    init(ids: [String] = [], index: Int = 0) {
        self.ids = ids
        self.index = ids.isEmpty ? 0 : min(max(index, 0), ids.count - 1)
    }

    var current: String? { ids.indices.contains(index) ? ids[index] : nil }
    var upcoming: [String] { ids.indices.contains(index) ? Array(ids[(index + 1)...]) : [] }
    var history: [String] { ids.indices.contains(index) ? Array(ids[..<index]) : [] }
    var isEmpty: Bool { ids.isEmpty }

    /// Plays `id`. With a `list` that contains it, the list becomes the queue. Otherwise it jumps to the
    /// id if it is already queued, or slots it in right after the current track.
    mutating func play(_ id: String, in list: [String]? = nil) {
        if let list, let i = list.firstIndex(of: id) {
            ids = list; index = i
        } else if let i = ids.firstIndex(of: id) {
            index = i
        } else if ids.isEmpty {
            ids = [id]; index = 0
        } else {
            ids.insert(id, at: index + 1); index += 1
        }
    }

    mutating func jump(to i: Int) {
        if ids.indices.contains(i) { index = i }
    }

    /// Right after the current track.
    mutating func playNext(_ id: String) {
        if ids.isEmpty { ids = [id]; index = 0 } else { ids.insert(id, at: index + 1) }
    }

    mutating func enqueue(_ id: String) {
        ids.append(id)
    }

    /// Removes the entry at `i`. Removing something before the current track keeps the current track current;
    /// removing the current track itself moves on to whatever follows it.
    mutating func remove(at i: Int) {
        guard ids.indices.contains(i) else { return }
        ids.remove(at: i)
        if i < index { index -= 1 }
        index = ids.isEmpty ? 0 : min(index, ids.count - 1)
    }

    /// Drops every copy of `id` (a deleted local file).
    mutating func removeAll(_ id: String) {
        while let i = ids.firstIndex(of: id) { remove(at: i) }
    }

    mutating func clearUpcoming() {
        guard !ids.isEmpty else { return }
        ids = Array(ids[...index])
    }

    enum Advance: Equatable, Sendable { case moved, wrapped, ended }

    /// Where "next" goes. Shuffle picks a random *other* track. Otherwise the following one, the start again
    /// if repeat-all, or nothing at the end.
    mutating func advance(shuffle: Bool, repeatMode: RepeatMode,
                          pick: (_ count: Int, _ excluding: Int) -> Int = PlayQueue.randomOther) -> Advance {
        guard !ids.isEmpty else { return .ended }
        if shuffle && ids.count > 1 {
            index = pick(ids.count, index)
            return .moved
        }
        if index < ids.count - 1 { index += 1; return .moved }
        if repeatMode == .all { index = 0; return .wrapped }
        return .ended
    }

    /// "Previous": restart the track if it has played for more than 3 s (or this is the first one),
    /// otherwise go back one. Returns true when the queue moved.
    mutating func previous(progress: TimeInterval) -> Bool {
        if progress > 3 || index == 0 { return false }
        index -= 1
        return true
    }

    static func randomOther(count: Int, excluding: Int) -> Int {
        guard count > 1 else { return 0 }
        var n = excluding
        while n == excluding { n = Int.random(in: 0..<count) }
        return n
    }
}

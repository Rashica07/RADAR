import Foundation

/// Deterministic hashing and pseudo-random generation, ported bit-for-bit from the
/// Phase 01 web artifact so every generated cover, chart and waveform matches it exactly.
///
/// The web build used a 32-bit FNV-1a hash over UTF-16 code units and a
/// mulberry32-style generator. Swift's wrapping `UInt32` arithmetic reproduces the
/// low 32 bits that JavaScript's `Math.imul` and `>>> 0` produce.
enum SeededHash {
    /// 32-bit FNV-1a over UTF-16 code units (JavaScript `charCodeAt` semantics).
    static func fnv1a(_ string: String) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for unit in string.utf16 {
            hash ^= UInt32(unit)
            hash = hash &* 16_777_619
        }
        return hash
    }
}

/// A small, fast, deterministic generator. Not for cryptography.
struct SeededRandom {
    private var state: UInt32

    init(seed: UInt32) {
        state = seed
    }

    init(_ key: String) {
        self.init(seed: SeededHash.fnv1a(key))
    }

    /// Next value in `[0, 1)`.
    mutating func next() -> Double {
        state = state &+ 1_831_565_813
        var e = state
        e = (e ^ (e >> 15)) &* (e | 1)
        e ^= e &+ ((e ^ (e >> 7)) &* (e | 61))
        return Double(e ^ (e >> 14)) / 4_294_967_296
    }
}

/// Emulates V8's TimSort when called with a comparator that ignores its arguments
/// (`array.sort(() => rng() - 0.5)`). For arrays shorter than 64 elements V8 runs a
/// single run-detection pass followed by binary insertion sort, so the exact sequence
/// of comparator calls — and therefore of random draws — can be reproduced.
enum V8RandomSort {
    static func sort<T>(_ input: [T], comparator: () -> Double) -> [T] {
        var a = input
        let n = a.count
        guard n >= 2, n < 64 else { return a }

        // CountAndMakeRun(0, n)
        var runLength = 2
        let firstOrder = comparator()
        let descending = firstOrder < 0
        var idx = 2
        while idx < n {
            let order = comparator()
            if descending {
                if order >= 0 { break }
            } else if order < 0 {
                break
            }
            runLength += 1
            idx += 1
        }
        if descending {
            a[0..<runLength].reverse()
        }

        // BinaryInsertionSort(low: 0, start: runLength, high: n)
        var start = runLength
        while start < n {
            var left = 0
            var right = start
            let pivot = a[start]
            while left < right {
                let mid = left + ((right - left) >> 1)
                let order = comparator()
                if order < 0 { right = mid } else { left = mid + 1 }
            }
            var p = start
            while p > left {
                a[p] = a[p - 1]
                p -= 1
            }
            a[left] = pivot
            start += 1
        }
        return a
    }
}

import AVFoundation
import Foundation
import Observation
import OSLog
import UniformTypeIdentifiers

/// Audio files the user imported from Files. These are **real**: they are copied into
/// the app's private container, read with AVFoundation and played back for real.
/// Nothing is uploaded anywhere.
@MainActor
@Observable
final class LocalLibrary {
    static let supportedTypes: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]

    private static let key = "local-files"
    private let persistence: PersistenceController
    private let log = Logger(subsystem: "app.radar", category: "local-library")

    let directory: URL
    private(set) var tracks: [Track] { didSet { persistence.save(tracks, key: Self.key) } }
    private(set) var isImporting = false

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("RADAR/Imported", isDirectory: true)
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stored = persistence.load([Track].self, key: Self.key) ?? []
        // Drop entries whose file has gone missing. (Uses the local `directory`: `self` is not
        // fully initialised yet, so the closure must not capture it.)
        tracks = stored.filter { track in
            guard let name = track.local?.storedName else { return false }
            return FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path)
        }
    }

    func track(_ id: String) -> Track? { tracks.first { $0.id == id } }

    func fileURL(for track: Track) -> URL? {
        track.local.map { directory.appendingPathComponent($0.storedName) }
    }

    var totalBytes: Int64 { tracks.reduce(0) { $0 + ($1.local?.sizeBytes ?? 0) } }

    /// Copies picked files into the sandbox and reads their metadata.
    /// Returns the number of files imported.
    @discardableResult
    func importFiles(_ urls: [URL]) async -> (imported: Int, failed: Int) {
        isImporting = true
        defer { isImporting = false }
        var imported = 0, failed = 0
        for url in urls {
            if let track = await importFile(url) {
                tracks.insert(track, at: 0)
                imported += 1
            } else {
                failed += 1
            }
        }
        return (imported, failed)
    }

    private func importFile(_ source: URL) async -> Track? {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }

        let uuid = UUID().uuidString.lowercased()
        let ext = source.pathExtension.isEmpty ? "audio" : source.pathExtension.lowercased()
        let storedName = "\(uuid).\(ext)"
        let destination = directory.appendingPathComponent(storedName)
        let directory = self.directory

        do {
            // Copy off the main actor; files can be large.
            try await Task.detached(priority: .userInitiated) {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                var dest = destination
                try? dest.setResourceValues(values)
            }.value
        } catch {
            log.error("Copy failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        let meta = await AudioMetadata.read(destination)
        guard meta.duration > 0 else {
            log.error("Not playable audio: \(source.lastPathComponent, privacy: .public)")
            try? FileManager.default.removeItem(at: destination)
            return nil
        }
        let size = (try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        let baseName = source.deletingPathExtension().lastPathComponent

        return Track(
            id: "local-\(uuid)",
            title: meta.title ?? baseName,
            artistId: "local",
            genre: "Local",
            duration: meta.duration,
            daysAgo: 0,
            plays: 0,
            source: .local,
            download: .local,
            bpm: 0,
            explicit: false,
            discovery: false,
            why: nil,
            seed: "local-\(uuid)",
            albumId: nil,
            local: .init(
                storedName: storedName,
                originalName: source.lastPathComponent,
                artistName: meta.artist,
                albumTitle: meta.album,
                sizeBytes: size,
                addedAt: .now
            )
        )
    }

    func delete(_ id: String) {
        guard let track = track(id), let url = fileURL(for: track) else { return }
        try? FileManager.default.removeItem(at: url)
        tracks.removeAll { $0.id == id }
    }

    /// Days since import, for "Added" labels.
    func daysSinceAdded(_ track: Track) -> Int {
        guard let added = track.local?.addedAt else { return 0 }
        return Calendar.current.dateComponents([.day], from: added, to: .now).day ?? 0
    }
}

/// Async metadata reading with the modern `load(_:)` API.
enum AudioMetadata {
    struct Result: Sendable {
        var duration: Double = 0
        var title: String?
        var artist: String?
        var album: String?
    }

    static func read(_ url: URL) async -> Result {
        let asset = AVURLAsset(url: url)
        var result = Result()
        do {
            let (duration, metadata) = try await asset.load(.duration, .commonMetadata)
            let seconds = duration.seconds
            result.duration = seconds.isFinite ? seconds : 0
            result.title = await string(metadata, .commonIdentifierTitle)
            result.artist = await string(metadata, .commonIdentifierArtist)
            result.album = await string(metadata, .commonIdentifierAlbumName)
        } catch {
            return result
        }
        return result
    }

    private static func string(_ items: [AVMetadataItem], _ id: AVMetadataIdentifier) async -> String? {
        guard let item = AVMetadataItem.metadataItems(from: items, filteredByIdentifier: id).first,
              let value = try? await item.load(.stringValue) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// Reads real peak data from an imported file, streaming PCM so memory stays flat
/// regardless of file length. Results are cached per file.
actor WaveformAnalyzer {
    static let shared = WaveformAnalyzer()
    private var cache: [URL: [Double]] = [:]

    func peaks(for url: URL, resolution: Int = 256) async -> [Double]? {
        if let cached = cache[url] { return cached }
        guard let peaks = try? await analyze(url, resolution: resolution) else { return nil }
        cache[url] = peaks
        return peaks
    }

    private func analyze(_ url: URL, resolution: Int) async throws -> [Double] {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return [] }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ])
        output.alwaysCopiesSampleData = false
        reader.add(output)
        guard reader.startReading() else { return [] }

        // First pass: one peak per 2048 samples.
        let chunk = 2048
        var chunks: [Double] = []
        var currentPeak: Int32 = 0
        var counter = 0
        while let buffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            guard let block = CMSampleBufferGetDataBuffer(buffer) else { continue }
            var length = 0
            var pointer: UnsafeMutablePointer<Int8>?
            guard CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &pointer) == noErr,
                  let raw = pointer else { continue }
            let count = length / MemoryLayout<Int16>.size
            raw.withMemoryRebound(to: Int16.self, capacity: count) { samples in
                for i in 0..<count {
                    let v = abs(Int32(samples[i]))
                    if v > currentPeak { currentPeak = v }
                    counter += 1
                    if counter == chunk {
                        chunks.append(Double(currentPeak))
                        currentPeak = 0
                        counter = 0
                    }
                }
            }
        }
        if counter > 0 { chunks.append(Double(currentPeak)) }
        guard let maxPeak = chunks.max(), maxPeak > 0 else { return [] }
        let normalized = chunks.map { max(0.12, min(1, ($0 / maxPeak).squareRoot())) }
        return DemoCatalog.bucket(normalized, bars: resolution)
    }
}

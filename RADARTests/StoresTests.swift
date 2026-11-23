import XCTest
@testable import RADAR

/// Persistence and store rules. Each test uses its own temporary directory.
@MainActor
final class StoresTests: XCTestCase {
    private var dirs: [URL] = []

    private func makeDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("radar-tests-\(UUID().uuidString)")
        dirs.append(url)
        return url
    }

    override func tearDown() {
        for d in dirs { try? FileManager.default.removeItem(at: d) }
        dirs = []
        super.tearDown()
    }

    // MARK: PersistenceController

    func testPersistenceRoundTripAfterFlush() {
        let dir = makeDirectory()
        let a = PersistenceController(directory: dir)
        a.save(["x": 1, "y": 2], key: "t")
        a.flush()
        XCTAssertEqual(PersistenceController(directory: dir).load([String: Int].self, key: "t"), ["x": 1, "y": 2])
    }

    func testLastWriteWinsWhenCoalesced() {
        let dir = makeDirectory()
        let a = PersistenceController(directory: dir)
        a.save(1, key: "n"); a.save(2, key: "n"); a.save(3, key: "n")
        a.flush()
        XCTAssertEqual(PersistenceController(directory: dir).load(Int.self, key: "n"), 3)
    }

    func testCorruptFileIsDiscardedNotCrashed() throws {
        let dir = makeDirectory()
        let p = PersistenceController(directory: dir)
        try Data("not json".utf8).write(to: dir.appendingPathComponent("\(PersistenceController.namespace).bad.json"))
        XCTAssertNil(p.load([String].self, key: "bad"))
    }

    func testRemoveDeletesTheFile() {
        let dir = makeDirectory()
        let p = PersistenceController(directory: dir)
        p.save("v", key: "r"); p.flush()
        p.remove(key: "r")
        XCTAssertNil(PersistenceController(directory: dir).load(String.self, key: "r"))
    }

    // MARK: LibraryStore

    private func makeLibrary(_ dir: URL) -> LibraryStore {
        LibraryStore(catalog: .shared, persistence: PersistenceController(directory: dir))
    }

    func testLibraryStartsWithTheArtifactDefaults() {
        let lib = makeLibrary(makeDirectory())
        XCTAssertEqual(lib.saved, DemoCatalog.shared.defaultSaved)
        XCTAssertEqual(lib.searches, DemoCatalog.shared.defaultRecentSearches)
        XCTAssertEqual(lib.recent.count, DemoCatalog.shared.defaultRecent.count)
        XCTAssertEqual(lib.playlists.count, DemoCatalog.shared.personalPlaylistsSeed.count)
    }

    func testToggleSaveAddsToFrontAndRemoves() {
        let lib = makeLibrary(makeDirectory())
        let id = DemoCatalog.shared.tracks.first { !lib.isSaved($0.id) }!.id
        XCTAssertTrue(lib.toggleSave(id))
        XCTAssertEqual(lib.saved.first, id)
        XCTAssertFalse(lib.toggleSave(id))
        XCTAssertFalse(lib.isSaved(id))
    }

    /// Guards risk R1: property observers (`didSet`) on `@Observable` stored properties must
    /// still fire, otherwise nothing is ever persisted.
    func testLibraryChangesPersistAcrossInstances() {
        let dir = makeDirectory()
        let first = makeLibrary(dir)
        let id = DemoCatalog.shared.tracks.first { !first.isSaved($0.id) }!.id
        first.toggleSave(id)
        first.addSearch("zzz test")
        let playlist = first.createPlaylist()
        first.add(id, to: playlist.id)
        first.rename(playlist.id, to: "  Mine  ")
        // The store's controller coalesces writes for 0.35 s; wait for it to land on disk.
        let exp = expectation(description: "coalesced write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { exp.fulfill() }
        wait(for: [exp], timeout: 3)
        let second = makeLibrary(dir)
        XCTAssertEqual(second.saved.first, id)
        XCTAssertEqual(second.searches.first, "zzz test")
        XCTAssertEqual(second.playlist(playlist.id)?.title, "Mine")
        XCTAssertEqual(second.playlist(playlist.id)?.trackIds, [id])
    }

    func testRecentIsCappedAtThirtyAndDeduplicated() {
        let lib = makeLibrary(makeDirectory())
        let ids = DemoCatalog.shared.tracks.map(\.id)
        for id in ids { lib.addRecent(id) }
        lib.addRecent(ids[0])
        XCTAssertEqual(lib.recent.count, 30)
        XCTAssertEqual(lib.recent.first?.id, ids[0])
        XCTAssertEqual(Set(lib.recent.map(\.id)).count, 30)
    }

    func testSearchesAreCappedAtEightCaseInsensitiveAndTrimmed() {
        let lib = makeLibrary(makeDirectory())
        for i in 0..<12 { lib.addSearch("q\(i)") }
        XCTAssertEqual(lib.searches.count, 8)
        lib.addSearch("  Q11 ")
        XCTAssertEqual(lib.searches.first, "Q11")
        XCTAssertEqual(lib.searches.filter { $0.lowercased() == "q11" }.count, 1)
        lib.addSearch("   ")
        XCTAssertEqual(lib.searches.first, "Q11")
        lib.clearSearches()
        XCTAssertTrue(lib.searches.isEmpty)
    }

    func testPlaylistRules() {
        let lib = makeLibrary(makeDirectory())
        let a = lib.createPlaylist(), b = lib.createPlaylist()
        XCTAssertEqual(a.title, "New playlist 1")
        XCTAssertEqual(b.title, "New playlist 2")
        XCTAssertEqual(lib.playlists.first?.id, b.id)
        XCTAssertTrue(lib.add("t1", to: a.id))
        XCTAssertFalse(lib.add("t1", to: a.id), "duplicates are rejected")
        XCTAssertFalse(lib.add("t1", to: "missing"))
        lib.rename(a.id, to: "   ")
        XCTAssertEqual(lib.playlist(a.id)?.title, "New playlist 1", "blank rename is ignored")
        lib.remove(at: 5, from: a.id)
        XCTAssertEqual(lib.playlist(a.id)?.trackIds, ["t1"], "out-of-range removal is ignored")
        lib.remove(at: 0, from: a.id)
        XCTAssertEqual(lib.playlist(a.id)?.trackIds, [])
        lib.deletePlaylist(a.id)
        XCTAssertNil(lib.playlist(a.id))
    }

    func testPlaylistsCreatedInTheSameMillisecondGetDistinctIds() {
        let lib = makeLibrary(makeDirectory())
        let ids = (0..<50).map { _ in lib.createPlaylist().id }
        XCTAssertEqual(Set(ids).count, 50)
    }

    func testPurgeRemovesATrackEverywhere() {
        let lib = makeLibrary(makeDirectory())
        let p = lib.createPlaylist()
        let id = lib.saved[0]
        lib.add(id, to: p.id); lib.addRecent(id)
        lib.purge(trackId: id)
        XCTAssertFalse(lib.isSaved(id))
        XCTAssertFalse(lib.recent.contains { $0.id == id })
        XCTAssertEqual(lib.playlist(p.id)?.trackIds, [])
    }

    func testResetAllRestoresDefaults() {
        let lib = makeLibrary(makeDirectory())
        lib.unsave(lib.saved[0]); lib.clearSearches(); _ = lib.createPlaylist()
        lib.resetAll()
        XCTAssertEqual(lib.saved, DemoCatalog.shared.defaultSaved)
        XCTAssertEqual(lib.searches, DemoCatalog.shared.defaultRecentSearches)
        XCTAssertEqual(lib.playlists.count, DemoCatalog.shared.personalPlaylistsSeed.count)
    }

    // MARK: SettingsStore

    func testSettingsDefaultsToggleGenreAndReset() {
        let store = SettingsStore(persistence: PersistenceController(directory: makeDirectory()))
        XCTAssertEqual(store.settings, Settings())
        store.toggleGenre("House")
        XCTAssertFalse(store.settings.genres.contains("House"))
        store.toggleGenre("House")
        XCTAssertEqual(store.settings.genres.last, "House")
        store.settings.theme = .light
        store.reset()
        XCTAssertEqual(store.settings, Settings())
    }

    func testSettingsPersistAndMirrorHaptics() {
        let dir = makeDirectory()
        let store = SettingsStore(persistence: PersistenceController(directory: dir))
        store.settings.theme = .light
        store.settings.haptics = false
        XCTAssertFalse(Haptics.isEnabled)
        let exp = expectation(description: "coalesced write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { exp.fulfill() }
        wait(for: [exp], timeout: 3)
        let again = SettingsStore(persistence: PersistenceController(directory: dir))
        XCTAssertEqual(again.settings.theme, .light)
        XCTAssertFalse(again.settings.haptics)
        Haptics.isEnabled = true
    }
}

import XCTest
@testable import RADAR

/// Proves the Swift port of the Phase 01 JavaScript logic against vectors generated from the
/// ORIGINAL artifact code (tools/extract.js → Fixtures/ParityVectors.json).
final class ParityTests: XCTestCase {
    private struct Vectors: Decodable {
        struct Chart: Decodable {
            struct Entry: Decodable { let id: String; let rank: Int; let prev: Int?; let delta: Int }
            let country: String
            let window: String
            let entries: [Entry]
        }
        struct Search: Decodable { let q: String; let tracks: [String]; let artists: [String]; let albums: [String]; let playlists: [String] }
        struct Art: Decodable { let seed: UInt32; let palette: String; let style: String }
        let hash: [[Item]]
        let prng: [[Item]]
        let charts: [Chart]
        let movers: [String]
        let emerging: [String]
        let rising: [String]
        let newReleases: [String]
        let search: [Search]
        let related: [[Item]]
        let spark: [Double]
        let art: [[Item]]
        let wave: [Double]
    }

    /// The fixture mixes strings, numbers, arrays and objects inside tuples.
    private enum Item: Decodable {
        case string(String), number(Double), list([Item]), art(Vectors.Art), strings([String])
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let v = try? c.decode(String.self) { self = .string(v) }
            else if let v = try? c.decode(Double.self) { self = .number(v) }
            else if let v = try? c.decode(Vectors.Art.self) { self = .art(v) }
            else if let v = try? c.decode([String].self) { self = .strings(v) }
            else { self = .list(try c.decode([Item].self)) }
        }
        var string: String? { if case .string(let s) = self { s } else { nil } }
        var number: Double? { if case .number(let n) = self { n } else { nil } }
        var numbers: [Double]? { if case .list(let l) = self { l.compactMap(\.number) } else { nil } }
        var strings: [String]? { if case .strings(let s) = self { s } else { nil } }
        var art: Vectors.Art? { if case .art(let a) = self { a } else { nil } }
    }

    private var v: Vectors!
    private let catalog = DemoCatalog.shared

    override func setUpWithError() throws {
        v = try JSONDecoder().decode(Vectors.self, from: Fixture.data("ParityVectors"))
    }

    func testCatalogDecodesAndHasExpectedShape() {
        XCTAssertEqual(catalog.tracks.count, 46)
        XCTAssertEqual(catalog.artists.count, 23)
        XCTAssertEqual(catalog.albums.count, 10)
        XCTAssertEqual(catalog.playlists.count, 8)
        XCTAssertEqual(catalog.genres.count, 12)
        XCTAssertFalse(catalog.tracks.contains(where: \.isLocal))
    }

    func testFNV1aMatchesJavaScript() {
        XCTAssertEqual(v.hash.count, 5)
        for pair in v.hash {
            XCTAssertEqual(SeededHash.fnv1a(pair[0].string!), UInt32(pair[1].number!), pair[0].string!)
        }
    }

    func testPRNGMatchesJavaScript() {
        for pair in v.prng {
            var rng = SeededRandom(seed: UInt32(pair[0].number!))
            for (i, expected) in pair[1].numbers!.enumerated() {
                XCTAssertEqual(rng.next(), expected, accuracy: 1e-15, "seed \(pair[0].number!) draw \(i)")
            }
        }
    }

    func testChartsMatchJavaScript() {
        XCTAssertEqual(v.charts.count, 4)
        for chart in v.charts {
            let window = ChartWindow(rawValue: chart.window)!
            let got = catalog.chart(country: chart.country, window: window, limit: 20)
            let label = "\(chart.country)/\(chart.window)"
            XCTAssertEqual(got.map(\.track.id), chart.entries.map(\.id), label)
            XCTAssertEqual(got.map(\.rank), chart.entries.map(\.rank), label)
            XCTAssertEqual(got.map(\.previous), chart.entries.map(\.prev), label)
            XCTAssertEqual(got.map(\.delta), chart.entries.map(\.delta), label)
        }
    }

    func testMoversEmergingRisingNewReleasesMatchJavaScript() {
        XCTAssertEqual(catalog.movers(country: "IT", limit: 6).map(\.track.id), v.movers)
        XCTAssertEqual(catalog.emergingArtists(limit: 5).map(\.id), v.emerging)
        XCTAssertEqual(catalog.risingArtists(limit: 8).map(\.id), v.rising)
        XCTAssertEqual(catalog.newReleases(limit: 6).map(\.id), v.newReleases)
    }

    func testSearchMatchesJavaScript() {
        XCTAssertEqual(v.search.count, 6)
        for expected in v.search {
            let got = catalog.search(expected.q)
            XCTAssertEqual(got.tracks.map(\.id), expected.tracks, expected.q)
            XCTAssertEqual(got.artists.map(\.id), expected.artists, expected.q)
            XCTAssertEqual(got.albums.map(\.id), expected.albums, expected.q)
            XCTAssertEqual(got.playlists.map(\.id), expected.playlists, expected.q)
        }
    }

    func testRelatedMatchesJavaScript() {
        for pair in v.related {
            let track = catalog.track(pair[0].string!)!
            XCTAssertEqual(catalog.related(to: track, limit: 6).map(\.id), pair[1].strings, track.id)
        }
    }

    func testSparklineMatchesJavaScript() {
        let got = catalog.spark(artistId: "noor", growth: 96)
        XCTAssertEqual(got.count, v.spark.count)
        for (a, b) in zip(got, v.spark) { XCTAssertEqual(a, b, accuracy: 1e-9) }
    }

    func testWaveformMatchesJavaScript() {
        let got = DemoCatalog.waveform(trackId: "ottobre", bars: 72)
        XCTAssertEqual(got.count, v.wave.count)
        for (a, b) in zip(got, v.wave) { XCTAssertEqual(a, b, accuracy: 1e-9) }
    }

    func testArtSpecsMatchJavaScript() {
        let playlist = catalog.playlist("italy-rising")!
        let genre = catalog.genres.first { $0.id == "House" }!
        let results: [String: ArtSpec] = [
            "ottobre": catalog.art(for: catalog.track("ottobre")!),
            "noor": catalog.art(for: catalog.artist("noor")!),
            "italy": catalog.art(forPlaylistSeed: playlist.seed),
            "house": catalog.art(for: genre),
        ]
        for pair in v.art {
            let key = pair[0].string!, expected = pair[1].art!
            let got = results[key]!
            XCTAssertEqual(got.seed, expected.seed, key)
            XCTAssertEqual(got.palette.rawValue, expected.palette, key)
            XCTAssertEqual(got.style.rawValue, expected.style, key)
        }
    }
}

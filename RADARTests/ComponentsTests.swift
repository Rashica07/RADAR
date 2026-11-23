import SwiftUI
import XCTest
@testable import RADAR

final class ComponentsTests: XCTestCase {
    func testTitleSizesStepDownAndTrackTextStyles() {
        let sizes = [RadarScale.Title.hero, .large, .medium, .small].map(\.size)
        XCTAssertEqual(sizes, sizes.sorted(by: >))
        XCTAssertEqual(RadarScale.Title.small.size, 28)
        XCTAssertEqual(RadarScale.Title.hero.style, .largeTitle)
        XCTAssertEqual(RadarScale.touch, 44)
    }

    func testChartMove() {
        XCTAssertEqual(ChartMove(delta: 0, previous: nil), .new)
        XCTAssertEqual(ChartMove(delta: 3, previous: 5), .up(3))
        XCTAssertEqual(ChartMove(delta: -1, previous: 2), .down(1))
        XCTAssertEqual(ChartMove(delta: 0, previous: 4), .unchanged)
        XCTAssertEqual(ChartMove.up(1).accessibilityLabel, "Up 1 place")
        XCTAssertEqual(ChartMove.up(2).accessibilityLabel, "Up 2 places")
        XCTAssertEqual(ChartMove.down(1).accessibilityLabel, "Down 1 place")
        XCTAssertEqual(ChartMove.new.accessibilityLabel, "New entry")
        XCTAssertEqual(ChartMove.unchanged.accessibilityLabel, "Unchanged")
    }

    func testSparklineDomainLeavesAirAroundTheData() {
        let d = Sparkline.domain([10, 20, 15, 30])
        XCTAssertLessThan(d.lowerBound, 10); XCTAssertGreaterThan(d.upperBound, 30)
        XCTAssertEqual(d.lowerBound, 10 - 20 * 0.17, accuracy: 1e-9)
        // flat or empty data still gives a usable, non-empty range
        let flat = Sparkline.domain([5, 5, 5])
        XCTAssertLessThan(flat.lowerBound, 5); XCTAssertGreaterThan(flat.upperBound, 5)
        XCTAssertEqual(Sparkline.domain([]), 0...1)
        let spark = DemoCatalog.shared.spark(artistId: "noor", growth: 96)
        XCTAssertEqual(spark.count, 14)
        XCTAssertTrue(Sparkline.domain(spark).contains(spark.min()!) && Sparkline.domain(spark).contains(spark.max()!))
    }

    func testDownloadStatusTableMatchesTheArtifact() {
        XCTAssertEqual(DownloadStatus.available.presentation.label, "Download available")
        XCTAssertEqual(DownloadStatus.downloaded.presentation.icon, .check)
        XCTAssertEqual(DownloadStatus.streamingOnly.presentation.tone, .off)
        XCTAssertEqual(DownloadStatus.unavailable.presentation.icon, .lock)
        XCTAssertEqual(DownloadStatus.local.presentation.sub, "Local file · never uploaded")
        let toneOk = DownloadStatus.allCases.filter { $0.presentation.tone == .ok }
        XCTAssertEqual(Set(toneOk), [.available, .downloaded, .local])
    }

    @MainActor func testComponentsRenderWithoutCrashing() throws {
        var selection = "a"
        let binding = Binding(get: { selection }, set: { selection = $0 })
        let sheet = VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Rising now", idx: "02", kicker: "IT · 7 days", moving: true, sub: "Fresh signal", action: .init(label: "All", perform: {}))
            SectionHeader("Loading", loading: true, large: true)
            RadarTabs(items: [.init("a", "Saved", count: 4), .init("b", "Playlists")], selection: binding)
            Readout([.text("Week"), .separator, .strong("12"), .text(" plays")], hot: true)
            HStack { NewFlag(); ExplicitFlag(); DemoBadge(action: {}); SourceTag(source: .catalog, name: "Demo Catalog") }
            HStack { StatusLabel(status: .downloaded); MoveIndicator(delta: 2, previous: 3); MoveIndicator(.new); Sparkline(data: [1, 3, 2, 5]) }
            HStack {
                Button("Play") {}.buttonStyle(.radar(.primary)); Button("Share") {}.buttonStyle(.radar(.outline, size: .sm))
                Button("Open") {}.buttonStyle(.radarCTA); Button("Pop") {}.buttonStyle(.radarTag(on: true)); Button("Jazz") {}.buttonStyle(.radarSlash)
            }
        }.frame(width: 393).background(Color.radarBg)
        let r = ImageRenderer(content: sheet); r.scale = 1
        XCTAssertNotNil(r.cgImage)
    }
}

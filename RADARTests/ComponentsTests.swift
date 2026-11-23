import SwiftUI
import XCTest
@testable import RADAR

final class ComponentsTests: XCTestCase {
    func testFluidTypeClampsLikeCSS() {
        // --fs-hero: clamp(76px, 26vw, 176px)
        XCTAssertEqual(RadarScale.hero(393), 102.18, accuracy: 0.01)
        XCTAssertEqual(RadarScale.hero(200), 76); XCTAssertEqual(RadarScale.hero(1000), 176)
        // --fs-display-l: clamp(56px, 17vw, 104px); --fs-display-m: clamp(40px, 11vw, 56px)
        XCTAssertEqual(RadarScale.displayL(393), 66.81, accuracy: 0.01)
        XCTAssertEqual(RadarScale.displayL(320), 56); XCTAssertEqual(RadarScale.displayL(1024), 104)
        XCTAssertEqual(RadarScale.displayM(393), 43.23, accuracy: 0.01)
        XCTAssertEqual(RadarScale.displayM(300), 40); XCTAssertEqual(RadarScale.displayM(768), 56)
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

    func testSparklinePointsMatchTheArtifactFormula() {
        // JS: points = data.map((v,i) => `${i/(n-1)*w},${h-3-(v-min)/range*(h-6)}`) with w=72, h=24
        let p = Sparkline.points([10, 20, 15, 30], width: 72, height: 24)
        XCTAssertEqual(p.map(\.x), [0, 24, 48, 72])
        XCTAssertEqual(p[0].y, 21, accuracy: 1e-9)                  // min → bottom (h-3)
        XCTAssertEqual(p[3].y, 3, accuracy: 1e-9)                   // max → top (3)
        XCTAssertEqual(p[1].y, 24 - 3 - (10.0 / 20) * 18, accuracy: 1e-9)
        // flat data: range falls back to 1, line sits at the bottom
        XCTAssertEqual(Sparkline.points([5, 5, 5], width: 72, height: 24).map(\.y), [21, 21, 21])
        XCTAssertEqual(Sparkline.points([], width: 72, height: 24), [])
        XCTAssertEqual(Sparkline.points([7], width: 72, height: 24).first?.x, 0)      // JS would give NaN; we pin it
        // and with the real demo data
        let spark = DemoCatalog.shared.spark(artistId: "noor", growth: 96)
        let pts = Sparkline.points(spark, width: 72, height: 24)
        XCTAssertEqual(pts.count, 14)
        XCTAssertTrue(pts.allSatisfy { $0.y >= 3 - 1e-9 && $0.y <= 21 + 1e-9 })
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

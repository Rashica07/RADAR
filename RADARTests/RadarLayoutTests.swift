import SwiftUI
import XCTest
@testable import RADAR

/// Layout decisions come from the container size alone. These tests use abstract sample
/// sizes, never device names, because RADAR must not branch on the device. The comments say
/// which kind of window a size is typical of, for orientation only.
final class RadarLayoutTests: XCTestCase {
    private func profile(_ width: CGFloat, _ height: CGFloat) -> RadarLayoutProfile {
        RadarLayoutProfile.make(for: CGSize(width: width, height: height))
    }

    // MARK: Navigation

    func testNarrowContainersUseTheBottomBar() {
        // typical: iPhone portrait, a closed foldable, iPad Slide Over
        XCTAssertEqual(profile(375, 812).navigation, .bottomBar)
        XCTAssertEqual(profile(466, 678).navigation, .bottomBar)
        XCTAssertEqual(profile(719, 1000).navigation, .bottomBar)
    }

    func testMediumContainersUseTheRail() {
        XCTAssertEqual(profile(720, 600).navigation, .rail)
        XCTAssertEqual(profile(890, 626).navigation, .rail)
        XCTAssertEqual(profile(1099, 800).navigation, .rail)
    }

    func testLargeContainersUseTheSidebar() {
        XCTAssertEqual(profile(1100, 800).navigation, .sidebar)
        XCTAssertEqual(profile(1376, 1032).navigation, .sidebar)
    }

    // MARK: Breakpoint boundaries (artifact: 720 / 900 / 1000 / 1100 / 1280)

    func testBoundariesAreInclusiveAtTheBreakpoint() {
        XCTAssertEqual(profile(RadarBreakpoint.rail - 1, 900).navigation, .bottomBar)
        XCTAssertEqual(profile(RadarBreakpoint.rail, 900).navigation, .rail)

        XCTAssertFalse(profile(RadarBreakpoint.twoColumn - 1, 1400).usesTwoColumnPages)
        XCTAssertTrue(profile(RadarBreakpoint.twoColumn, 1400).usesTwoColumnPages)

        XCTAssertEqual(profile(RadarBreakpoint.sidebar - 1, 900).navigation, .rail)
        XCTAssertEqual(profile(RadarBreakpoint.sidebar, 900).navigation, .sidebar)

        XCTAssertFalse(profile(RadarBreakpoint.dock - 1, 900).supportsQueueDock)
        XCTAssertTrue(profile(RadarBreakpoint.dock, 900).supportsQueueDock)

        XCTAssertFalse(profile(RadarBreakpoint.dockOpensByDefault - 1, 900).queueDockOpensByDefault)
        XCTAssertTrue(profile(RadarBreakpoint.dockOpensByDefault, 900).queueDockOpensByDefault)
    }

    func testBreakpointsAreOrdered() {
        XCTAssertLessThan(RadarBreakpoint.rail, RadarBreakpoint.twoPanePlayer)
        XCTAssertLessThan(RadarBreakpoint.twoPanePlayer, RadarBreakpoint.twoColumn)
        XCTAssertLessThan(RadarBreakpoint.twoColumn, RadarBreakpoint.sidebar)
        XCTAssertLessThan(RadarBreakpoint.sidebar, RadarBreakpoint.dock)
        XCTAssertLessThan(RadarBreakpoint.dock, RadarBreakpoint.dockOpensByDefault)
    }

    // MARK: Player

    func testTallNarrowContainersKeepTheStackedPlayer() {
        XCTAssertFalse(profile(466, 678).usesTwoPanePlayer)
        XCTAssertFalse(profile(800, 1100).usesTwoPanePlayer, "tall and below 900: stacked")
    }

    func testWideContainersUseTheTwoPanePlayer() {
        XCTAssertTrue(profile(900, 1200).usesTwoPanePlayer, "artifact breakpoint applies regardless of height")
        XCTAssertTrue(profile(1032, 1376).usesTwoPanePlayer)
    }

    func testShortWideContainersGetTheTwoPanePlayerBelowTheBreakpoint() {
        // `[ASSUMPTION]` rule for open foldables / phones in landscape — judge on device.
        XCTAssertTrue(profile(890, 626).usesTwoPanePlayer)
        XCTAssertTrue(profile(844, 390).usesTwoPanePlayer)
        XCTAssertFalse(profile(630, 400).usesTwoPanePlayer, "below the minimum width")
        XCTAssertFalse(profile(700, 650).usesTwoPanePlayer, "nearly square: stacked")
    }

    // MARK: Dock & columns

    func testDockIsAvailableOnVeryWideContainersButOpenOnlyOnTheWidest() {
        XCTAssertFalse(profile(1032, 1376).supportsQueueDock)
        XCTAssertTrue(profile(1376, 1032).supportsQueueDock)
        XCTAssertFalse(profile(1376, 1032).queueDockOpensByDefault, "artifact: toggle, not open, below 1680")
        XCTAssertTrue(profile(1700, 1000).queueDockOpensByDefault)
    }

    // MARK: Player chrome (artifact: mini-player + bottom nav < 720, transport bar ≥ 720)

    func testPlayerChromeFollowsTheRailBreakpoint() {
        XCTAssertEqual(profile(466, 678).playerChrome, .miniPlayer)
        XCTAssertEqual(profile(719, 900).playerChrome, .miniPlayer)
        XCTAssertEqual(profile(720, 900).playerChrome, .transportBar)
        XCTAssertEqual(profile(1376, 1032).playerChrome, .transportBar)
    }

    // MARK: Design-gap rule — wide-shaped containers must not just scale up the narrow layout

    func testWideShapedMediumContainersGetTwoColumnPages() {
        XCTAssertTrue(profile(890, 626).usesTwoColumnPages, "short and wide: split pages, not one huge column")
        XCTAssertFalse(profile(800, 1000).usesTwoColumnPages, "tall: single column until 1000 pt")
        XCTAssertFalse(profile(719, 400).usesTwoColumnPages, "below the rail breakpoint")
        XCTAssertTrue(profile(1032, 1376).usesTwoColumnPages, "artifact breakpoint (1000) still applies")
    }

    func testGridColumnsAreAlwaysEven() {
        for width in stride(from: CGFloat(200), through: 2000, by: 10) {
            XCTAssertEqual(profile(width, 800).gridColumns % 2, 0, "width \(width)")
        }
        XCTAssertEqual(profile(400, 800).gridColumns, 2)
        XCTAssertEqual(profile(900, 800).gridColumns, 4)
    }

    func testContentIsCappedSoWideWindowsDoNotStretch() {
        XCTAssertEqual(profile(2400, 1200).contentMaxWidth, RadarLayoutProfile.maxContentWidth)
        XCTAssertEqual(RadarLayoutProfile.maxContentWidth, 1360)
    }

    // MARK: Container-based, not orientation- or device-based

    func testDecisionsDependOnWidthNotOnOrientationLabels() {
        // Same width, different height → same navigation and column decisions.
        XCTAssertEqual(profile(1032, 1376).navigation, profile(1032, 700).navigation)
        XCTAssertEqual(profile(1032, 1376).usesTwoColumnPages, profile(1032, 700).usesTwoColumnPages)
        XCTAssertEqual(profile(1032, 1376).supportsQueueDock, profile(1032, 700).supportsQueueDock)
        XCTAssertEqual(profile(1032, 1376).playerChrome, profile(1032, 700).playerChrome)
    }

    func testProfileFollowsAResizeInBothDirections() {
        var sequence: [RadarNavigationStyle] = []
        for width in [400, 800, 1200, 800, 400] as [CGFloat] { sequence.append(profile(width, 800).navigation) }
        XCTAssertEqual(sequence, [.bottomBar, .rail, .sidebar, .rail, .bottomBar])
    }

    func testZeroSizeDefaultIsCompactAndSafe() {
        let neutral = RadarLayoutProfile.make(for: .zero)
        XCTAssertEqual(neutral.navigation, .bottomBar)
        XCTAssertFalse(neutral.usesTwoPanePlayer)
        XCTAssertEqual(neutral.playerChrome, .miniPlayer)
        XCTAssertFalse(neutral.supportsQueueDock)
    }

    func testShapeIsDerivedFromTheContainerNotTheDevice() {
        XCTAssertTrue(profile(890, 626).isLandscapeShaped)
        XCTAssertFalse(profile(466, 678).isLandscapeShaped)
        XCTAssertFalse(profile(500, 500).isLandscapeShaped)
    }
}

import XCTest
@testable import RADAR

@MainActor
final class RouterTests: XCTestCase {
    func testSwitchingTabs() {
        let r = AppRouter()
        XCTAssertEqual(r.selected, .discover)
        XCTAssertEqual(r.select(.library), .switched)
        XCTAssertEqual(r.selected, .library)
    }

    func testRetapAtRootDoesNothing() {
        let r = AppRouter()
        XCTAssertEqual(r.select(.discover), .alreadyAtRoot)
    }

    func testRetapPopsToRoot() {
        let r = AppRouter()
        r.push(.settings)
        XCTAssertEqual(r.paths[.discover]?.count, 1)
        XCTAssertEqual(r.select(.discover), .poppedToRoot)
        XCTAssertEqual(r.paths[.discover] ?? [], [])
    }

    func testPathsAreIndependentPerTabAndSurviveSwitching() {
        let r = AppRouter()
        r.push(.settings, on: .library)
        r.select(.trending)
        r.select(.library)
        XCTAssertEqual(r.paths[.library]?.count, 1)
        XCTAssertEqual(r.paths[.trending] ?? [], [])
    }

    func testPathBindingWritesThrough() {
        let r = AppRouter()
        let b = r.path(for: .search)
        b.wrappedValue = [.settings]
        XCTAssertEqual(r.paths[.search], [.settings])
    }

    func testFourTabsWithUniqueIcons() {
        XCTAssertEqual(AppTab.allCases.count, 4)
        XCTAssertEqual(Set(AppTab.allCases.map(\.icon)).count, 4)
    }
}

final class SwipeTests: XCTestCase {
    private func decide(_ tx: CGFloat, _ ty: CGFloat, px: CGFloat? = nil, py: CGFloat? = nil) -> PlayerSwipe {
        PlayerSwipe.decide(translation: CGSize(width: tx, height: ty), predicted: CGSize(width: px ?? tx, height: py ?? ty))
    }

    func testSidewaysSkips() {
        XCTAssertEqual(decide(-90, 5), .next)
        XCTAssertEqual(decide(90, -5), .previous)
    }

    func testShortDragDoesNothing() {
        XCTAssertEqual(decide(-20, 0), .none)
        XCTAssertEqual(decide(0, -20), .none)
    }

    func testUpExpands() {
        XCTAssertEqual(decide(4, -80), .expand)
    }

    func testDownDoesNotExpand() {
        XCTAssertEqual(decide(0, 120), .none)
    }

    func testFlickCountsViaPredictedEnd() {
        XCTAssertEqual(decide(-30, 0, px: -200, py: 0), .next)
    }

    func testDiagonalFavoursTheDominantAxis() {
        XCTAssertEqual(decide(-100, -60), .next)
        XCTAssertEqual(decide(-30, -120), .expand)
    }
}

final class DismissTests: XCTestCase {
    func testFarPullDismisses() {
        XCTAssertTrue(SheetDismiss.shouldDismiss(translation: 300, predicted: 320, height: 800))
    }

    func testSmallPullSnapsBack() {
        XCTAssertFalse(SheetDismiss.shouldDismiss(translation: 60, predicted: 120, height: 800))
    }

    func testHardFlickDismisses() {
        XCTAssertTrue(SheetDismiss.shouldDismiss(translation: 80, predicted: 500, height: 800))
    }

    func testUpwardNeverDismisses() {
        XCTAssertFalse(SheetDismiss.shouldDismiss(translation: -200, predicted: -400, height: 800))
    }

    func testRubberBandResistsAndStaysBounded() {
        XCTAssertEqual(SheetDismiss.rubber(50), 50)
        let small = SheetDismiss.rubber(-20), large = SheetDismiss.rubber(-2000)
        XCTAssertLessThan(abs(small), 20)
        XCTAssertGreaterThan(large, -80)
        XCTAssertLessThan(large, small)
    }
}

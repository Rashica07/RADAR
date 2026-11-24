import SwiftUI
import XCTest
@testable import RADAR

final class OwnUITests: XCTestCase {
    func testScrubFractionClampsToTrack() {
        XCTAssertEqual(ScrubBarMath.fraction(x: -20, width: 200), 0)
        XCTAssertEqual(ScrubBarMath.fraction(x: 100, width: 200), 0.5)
        XCTAssertEqual(ScrubBarMath.fraction(x: 999, width: 200), 1)
        XCTAssertEqual(ScrubBarMath.fraction(x: 10, width: 0), 0)
    }

    func testFarPullDismissesSmallPullDoesNot() {
        XCTAssertTrue(SheetDismiss.shouldDismiss(translation: 300, predicted: 320, height: 800))
        XCTAssertFalse(SheetDismiss.shouldDismiss(translation: 60, predicted: 120, height: 800))
        XCTAssertTrue(SheetDismiss.shouldDismiss(translation: 80, predicted: 500, height: 800))
        XCTAssertFalse(SheetDismiss.shouldDismiss(translation: -200, predicted: -400, height: 800))
    }

    func testEveryPaletteTintIsDarkEnoughForWhiteText() {
        for palette in ArtPalette.allCases {
            let ui = UIColor(palette.tint)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: &a)
            func lin(_ c: CGFloat) -> CGFloat { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
            let luminance = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
            // White text needs a contrast of at least 4.5:1: luminance below about 0.18.
            XCTAssertLessThan(luminance, 0.18, "\(palette)")
        }
    }
}

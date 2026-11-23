import XCTest
@testable import RADAR

@MainActor
final class OverlaysTests: XCTestCase {
    func testToastShowReplacesAndDismissClears() {
        let c = ToastCenter(duration: .seconds(60))
        c.show("One")
        let first = c.current?.id
        c.show("Two", icon: .check)
        XCTAssertEqual(c.current?.message, "Two")
        XCTAssertNotEqual(c.current?.id, first)
        c.dismiss()
        XCTAssertNil(c.current)
    }

    func testToastAutoDismisses() async throws {
        let c = ToastCenter(duration: .milliseconds(40))
        c.show("Soon gone")
        XCTAssertNotNil(c.current)
        for _ in 0..<40 where c.current != nil { try await Task.sleep(for: .milliseconds(50)) }   // up to 2 s, so a busy machine can't flake it
        XCTAssertNil(c.current)
    }

    func testOldToastTimerDoesNotDismissNewerToast() async throws {
        let c = ToastCenter(duration: .milliseconds(500))
        c.show("A")
        try await Task.sleep(for: .milliseconds(300))
        c.show("B")
        try await Task.sleep(for: .milliseconds(300))   // A would have expired by now (600 ms), B has not (800 ms)
        XCTAssertEqual(c.current?.message, "B")
    }

    func testDemoDataSheetStatesWhatIsSimulatedAndWhatIsReal() {
        let text = AboutDemoDataSheet.points.map { $0.title + " " + $0.body }.joined(separator: " ").lowercased()
        XCTAssertTrue(text.contains("simulated"))
        XCTAssertTrue(text.contains("your own files are real"))
        XCTAssertEqual(AboutDemoDataSheet.points.count, 4)
    }
}

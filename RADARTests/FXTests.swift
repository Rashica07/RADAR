import SwiftUI
import XCTest
@testable import RADAR

final class FXTests: XCTestCase {
    func testCubicBezierEndpointsAndShape() {
        for curve in [CubicBezier.ease, .easeOut, .easeInOut, .spring] {
            XCTAssertEqual(curve.value(at: 0), 0); XCTAssertEqual(curve.value(at: 1), 1)
        }
        // CSS ease-in-out is symmetric around the midpoint
        XCTAssertEqual(CubicBezier.easeInOut.value(at: 0.5), 0.5, accuracy: 1e-6)
        // --m-ease (.2,.8,.2,1) rushes ahead early
        XCTAssertGreaterThan(CubicBezier.ease.value(at: 0.25), 0.5)
        // spring overshoots 1 before settling
        XCTAssertGreaterThan((1...19).map { CubicBezier.spring.value(at: Double($0) / 20) }.max()!, 1.0)
        var last = 0.0
        for i in 0...50 { let v = CubicBezier.ease.value(at: Double(i) / 50); XCTAssertGreaterThanOrEqual(v, last); last = v }
    }

    func testSliceKeyframesHoldInHardSteps() {
        XCTAssertEqual(GlitchSlice.frame(.a, progress: 0), SliceFrame(top: 0.06, bottom: 0.78, dx: -7))
        XCTAssertEqual(GlitchSlice.frame(.a, progress: 0.17), SliceFrame(top: 0.06, bottom: 0.78, dx: -7))
        XCTAssertEqual(GlitchSlice.frame(.a, progress: 0.18), SliceFrame(top: 0.44, bottom: 0.30, dx: 5))
        XCTAssertEqual(GlitchSlice.frame(.a, progress: 0.99), SliceFrame(top: 0.24, bottom: 0.50, dx: 3))
        XCTAssertEqual(GlitchSlice.frame(.b, progress: 0.5), SliceFrame(top: 0.50, bottom: 0.28, dx: 4))
        XCTAssertEqual(GlitchSlice.frame(.b, progress: 0.66), SliceFrame(top: 0.82, bottom: 0.02, dx: -3))
        // after the burst the slices rest at ±fx-rgb, thin bands (8–10 % tall)
        XCTAssertEqual(GlitchSlice.frame(.a, progress: 1), SliceFrame(top: 0.24, bottom: 0.68, dx: -2.4))
        XCTAssertEqual(GlitchSlice.frame(.b, progress: 5), SliceFrame(top: 0.66, bottom: 0.24, dx: 2))
        XCTAssertEqual(GlitchSlice.frame(.a, progress: -1), GlitchSlice.frame(.a, progress: 0))
    }

    func testBurstStepsMatchKeyframes() {
        XCTAssertEqual(FXBurstTiming.step(progress: 0), BurstStep(dx: 6, tear: true))
        XCTAssertEqual(FXBurstTiming.step(progress: 0.21), BurstStep(dx: 6, tear: true))
        XCTAssertEqual(FXBurstTiming.step(progress: 0.22), BurstStep(dx: 2, tear: false))
        XCTAssertEqual(FXBurstTiming.step(progress: 0.5), BurstStep(dx: 4, tear: false))
        XCTAssertEqual(FXBurstTiming.step(progress: 0.8), BurstStep(dx: 2, tear: false))
        XCTAssertNil(FXBurstTiming.step(progress: 1)); XCTAssertNil(FXBurstTiming.step(progress: -0.1))
    }

    func testTearOffsetsAreDeterministicAndBounded() {
        let a = FXBurstTiming.tearOffsets(bands: 14)
        XCTAssertEqual(a, FXBurstTiming.tearOffsets(bands: 14))
        XCTAssertEqual(a.count, 14)
        XCTAssertTrue(a.allSatisfy { abs($0) <= 7 })
        XCTAssertGreaterThan(Set(a).count, 8)
    }

    func testEQBars() {
        XCTAssertEqual(EQTiming.height(bar: 1, time: 3, playing: false), 0.85)
        // bar 0, no delay: starts at 25 %, peaks at 100 % at 0.45 s (t=.5), steps in sixths
        XCTAssertEqual(EQTiming.height(bar: 0, time: 0, playing: true), 0.25, accuracy: 1e-9)
        XCTAssertEqual(EQTiming.height(bar: 0, time: 0.4499, playing: true), 0.25 + 0.75 * 5 / 6, accuracy: 1e-9)
        XCTAssertEqual(EQTiming.height(bar: 0, time: 0.45, playing: true), 1, accuracy: 1e-9)
        XCTAssertEqual(EQTiming.height(bar: 0, time: 0.9, playing: true), 0.25, accuracy: 1e-9)
        // negative delay shifts later bars ahead: bar 1 (-0.3 s) at t=0 behaves like bar 0 at t=0.3
        XCTAssertEqual(EQTiming.height(bar: 1, time: 0, playing: true), EQTiming.height(bar: 0, time: 0.3, playing: true), accuracy: 1e-9)
        for i in 0..<4 { for k in 0..<50 {
            let h = EQTiming.height(bar: i, time: Double(k) * 0.037, playing: true)
            XCTAssertTrue(h >= 0.25 - 1e-9 && h <= 1 + 1e-9, "bar \(i) t=\(k): \(h)")
        } }
    }

    func testPingAndSkeletonTiming() {
        let start = PingTiming.state(time: 0)
        XCTAssertEqual(start.opacity, 0.9, accuracy: 1e-9); XCTAssertEqual(start.scale, 1, accuracy: 1e-9)
        let mid = PingTiming.state(time: 1.0)
        XCTAssertLessThan(mid.opacity, 0.9); XCTAssertGreaterThan(mid.scale, 1)
        let rest = PingTiming.state(time: 2.5)                    // 78 % — holds at invisible, 3.2×
        XCTAssertEqual(rest.opacity, 0); XCTAssertEqual(rest.scale, 3.2)
        XCTAssertEqual(PingTiming.state(time: 3.2).opacity, 0.9, accuracy: 1e-9)   // loops

        XCTAssertEqual(SkeletonTiming.offset(time: 0), -1)
        XCTAssertEqual(SkeletonTiming.offset(time: 1.3 / 16 - 0.001), -1)          // holds for a whole step
        XCTAssertEqual(SkeletonTiming.offset(time: 1.3 / 16 + 0.001), -1 + 3.6 / 16, accuracy: 1e-9)
        XCTAssertEqual(SkeletonTiming.offset(time: 1.3 * 15.5 / 16), -1 + 3.6 * 15 / 16, accuracy: 1e-9)
    }

    func testGrainTile() {
        let tile = GrainTile.image
        XCTAssertEqual(tile.width, 180); XCTAssertEqual(tile.height, 180)
        let bytes = [UInt8](tile.dataProvider!.data! as Data)
        let alphas = stride(from: 3, to: bytes.count, by: 4).map { Double(bytes[$0]) / 255 }
        let mean = alphas.reduce(0, +) / Double(alphas.count)
        XCTAssertEqual(mean, 0.45, accuracy: 0.03)             // ≈ 0.9 × 0.5
        XCTAssertGreaterThan(Set(alphas).count, 100)           // real noise, not a flat tone
        XCTAssertTrue(alphas.allSatisfy { $0 <= 0.9 + 1e-9 })
    }

    // MARK: Rendering

    @MainActor private func pixels<V: View>(_ view: V, _ w: Int, _ h: Int) throws -> [UInt8] {
        let r = ImageRenderer(content: view.frame(width: CGFloat(w), height: CGFloat(h)))
        r.scale = 1
        let img = try XCTUnwrap(r.cgImage)
        var out = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &out, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        return out
    }
    private func px(_ p: [UInt8], _ x: Int, _ y: Int, _ w: Int) -> (Int, Int, Int) {
        let i = (y * w + x) * 4; return (Int(p[i]), Int(p[i + 1]), Int(p[i + 2]))
    }

    @MainActor func testChannelSplitWithZeroOffsetIsIdentity() throws {
        let art = HStack(spacing: 0) {
            Color(red: 0.9, green: 0.4, blue: 0.2); Color(red: 0.1, green: 0.7, blue: 0.8)
        }
        let plain = try pixels(art, 40, 20)
        let split = try pixels(RGBSplit(dx: 0) { art }, 40, 20)
        for x in stride(from: 0, to: 40, by: 7) {
            let a = px(plain, x, 10, 40), b = px(split, x, 10, 40)
            XCTAssertEqual(a.0, b.0, accuracy: 2); XCTAssertEqual(a.1, b.1, accuracy: 2); XCTAssertEqual(a.2, b.2, accuracy: 2)
        }
    }

    @MainActor func testChannelSplitFringesAnEdge() throws {
        // white block on black: red moves left (fringe on the black side), blue right (on the white side)
        let art = HStack(spacing: 0) { Color.black.frame(width: 20); Color.white.frame(width: 20) }
        let p = try pixels(RGBSplit(dx: 4) { art }, 40, 10)
        let left = px(p, 18, 5, 40)    // inside the black side, within 4 pt of the edge: red has moved here
        XCTAssertGreaterThan(left.0, 200); XCTAssertLessThan(left.2, 30)   // red only
        let right = px(p, 22, 5, 40)   // inside the white side: red moved away, blue still there
        XCTAssertGreaterThan(right.0, 200); XCTAssertGreaterThan(right.1, 200); XCTAssertLessThan(right.2, 30)   // yellow: blue has not arrived yet
    }

    @MainActor func testGlitchTextAndOverlaysRender() throws {
        let text = GlitchText(text: "RADAR", font: .system(size: 40, weight: .black), color: .white, animateOnAppear: false)
            .background(Color.black)
        let p = try pixels(text, 160, 60)
        var colours = Set<[UInt8]>(); for i in stride(from: 0, to: p.count, by: 4 * 5) { colours.insert(Array(p[i..<i + 3])) }
        XCTAssertGreaterThan(colours.count, 3)
        // scanlines darken every 3rd row of a flat white field by ~5 %
        let scanned = try pixels(Color.white.overlay { ArtFXOverlay() }, 30, 30)
        let rows = (0..<9).map { px(scanned, 5, $0, 30).0 }
        XCTAssertGreaterThan(Set(rows).count, 1)
        // FX switched off → overlay draws nothing
        let off = try pixels(Color.white.overlay { ArtFXOverlay() }.environment(\.radarFX, RadarFXEnvironment(enabled: false)), 30, 30)
        XCTAssertEqual(px(off, 5, 1, 30).0, 255)
    }

    @MainActor func testEQSkeletonPingRender() throws {
        for v in [AnyView(EQBars(playing: false)), AnyView(SkeletonBlock()), AnyView(PingBlip())] {
            let p = try pixels(v.background(Color.black), 24, 24)
            XCTAssertTrue(p.contains { $0 > 20 }, "drew nothing")
        }
    }
}

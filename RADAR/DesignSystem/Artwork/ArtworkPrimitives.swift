import Foundation

/// One drawing primitive in the 200×200 artwork space. A literal port of the SVG elements the
/// Phase 01 web artifact's eight cover generators emit (`mi, hi, gi, _i, vi, yi, bi, xi`), so
/// the output can be compared one-to-one against vectors produced by the original JavaScript
/// (`tools/gen-art-vectors.js` → `RADARTests/Fixtures/ArtVectors.json`).
struct ArtPrimitive: Equatable, Sendable {
    enum Kind: String, Sendable { case rect, circle, ellipse, path, line, g }

    var kind: Kind
    /// Numeric attributes (`cx`, `r`, `strokeWidth`, `opacity`…).
    var num: [String: Double] = [:]
    /// Text attributes (`fill`, `stroke`, `d`, `transform`) — colours as `#RRGGBB`.
    var text: [String: String] = [:]
    var children: [ArtPrimitive] = []
}

enum ArtworkPrimitives {
    /// Draws the cover described by `spec` as primitives in a 200×200 space.
    static func generate(_ spec: ArtSpec) -> [ArtPrimitive] {
        var rng = SeededRandom(seed: spec.seed)
        let p = spec.palette.hex.map(hexString)
        switch spec.style {
        case .rings: return rings(&rng, p)
        case .sweep: return sweep(&rng, p)
        case .bars: return bars(&rng, p)
        case .dots: return dots(&rng, p)
        case .arcs: return arcs(&rng, p)
        case .blocks: return blocks(&rng, p)
        case .waves: return waves(&rng, p)
        case .orbit: return orbit(&rng, p)
        }
    }

    // MARK: - Number formatting (matches JavaScript's Number → string for the values used here)

    /// The artifact's `F`: round to one decimal, JavaScript `Math.round` (half up).
    static func f(_ x: Double) -> Double { (x * 10 + 0.5).rounded(.down) / 10 }

    /// `String(x)` as JavaScript prints it for the one-decimal and integer values we produce.
    static func js(_ x: Double) -> String {
        if x == 0 { return "0" }
        if x == x.rounded(), abs(x) < 1e15 { return String(Int64(x)) }
        return "\(x)"
    }

    static func hexString(_ v: UInt32) -> String { String(format: "#%06X", v) }

    // MARK: - Helpers

    private static func bg(_ c: String) -> ArtPrimitive {
        ArtPrimitive(kind: .rect, num: ["width": 200, "height": 200], text: ["fill": c])
    }

    private static func circle(_ cx: Double, _ cy: Double, _ r: Double, fill: String,
                               stroke: String? = nil, strokeWidth: Double? = nil,
                               opacity: Double? = nil) -> ArtPrimitive {
        var n: [String: Double] = ["cx": cx, "cy": cy, "r": r]
        var t: [String: String] = ["fill": fill]
        if let stroke { t["stroke"] = stroke }
        if let strokeWidth { n["strokeWidth"] = strokeWidth }
        if let opacity { n["opacity"] = opacity }
        return ArtPrimitive(kind: .circle, num: n, text: t)
    }

    // MARK: - The eight generators (rng call order is significant)

    private static func rings(_ e: inout SeededRandom, _ p: [String]) -> [ArtPrimitive] {
        let (t, n, r, i) = (p[0], p[1], p[2], p[3])
        let a = 70 + e.next() * 60
        let o = 70 + e.next() * 60
        let s = 5 + Int((e.next() * 3).rounded(.down))
        let c = [n, r, i, n, r, i, n]
        var out = [bg(t)]
        for k in stride(from: s, through: 1, by: -1) {
            let radius = 150 / Double(s) * Double(k)
            let sw = 1 + e.next() * 9
            out.append(circle(f(a), f(o), f(radius), fill: k % 2 != 0 ? "none" : c[k % 7],
                              stroke: c[(k + 1) % 7], strokeWidth: f(sw), opacity: k == s ? 0.5 : 0.95))
        }
        let u = e.next() * Double.pi * 2
        let d = Double(s - 1) * (150 / Double(s))
        out.append(circle(f(a + cos(u) * d), f(o + sin(u) * d), 9, fill: i))
        return out
    }

    private static func sweep(_ e: inout SeededRandom, _ p: [String]) -> [ArtPrimitive] {
        let (t, n, r, i) = (p[0], p[1], p[2], p[3])
        let a = 40 + e.next() * 120
        let o = 100 + e.next() * 90
        let s = -Double.pi * (0.2 + e.next() * 0.6)
        let c = 1 + e.next() * 0.5
        let l = s + c
        func u(_ angle: Double) -> (String, String) {
            (js(f(a + cos(angle) * 260)), js(f(o + sin(angle) * 260)))
        }
        var out = [bg(t)]
        for k in 1...6 {
            out.append(ArtPrimitive(kind: .circle,
                                    num: ["cx": f(a), "cy": f(o), "r": Double(k * 32),
                                          "strokeOpacity": 0.4, "strokeWidth": 1.2],
                                    text: ["fill": "none", "stroke": i]))
        }
        for (e0, opacity) in [(1.0, 0.2), (0.72, 0.34), (0.46, 0.55), (0.2, 0.95)] {
            let from = u(l - c * e0), to = u(l)
            let d = "M\(js(f(a))) \(js(f(o))) L\(from.0) \(from.1) A260 260 0 0 1 \(to.0) \(to.1) Z"
            out.append(ArtPrimitive(kind: .path, num: ["opacity": opacity], text: ["d": d, "fill": n]))
        }
        let end = u(l)
        out.append(ArtPrimitive(kind: .line,
                                num: ["x1": f(a), "y1": f(o), "x2": Double(end.0)!, "y2": Double(end.1)!,
                                      "strokeWidth": 2.6],
                                text: ["stroke": r]))
        let ff = s + c * (0.3 + e.next() * 0.5)
        let pp = 40 + e.next() * 80
        out.append(circle(f(a + cos(ff) * pp), f(o + sin(ff) * pp), 8, fill: i))
        return out
    }

    private static func bars(_ e: inout SeededRandom, _ p: [String]) -> [ArtPrimitive] {
        let (t, n, r, i) = (p[0], p[1], p[2], p[3])
        let cx = 60 + e.next() * 80
        let cy = 60 + e.next() * 80
        let radius = 58 + e.next() * 20
        var out = [bg(t), circle(cx, cy, radius, fill: n)]
        var o = 30 + e.next() * 40
        for k in 0..<15 {
            o = max(10, min(150, o + (e.next() - 0.5) * 60))
            out.append(ArtPrimitive(kind: .rect,
                                    num: ["x": f(14 + Double(k) * 12.4), "y": f(100 - o / 2), "width": 7, "height": f(o)],
                                    text: ["fill": k % 4 == 0 ? i : r]))
        }
        return out
    }

    private static func dots(_ e: inout SeededRandom, _ p: [String]) -> [ArtPrimitive] {
        let (t, n, r) = (p[0], p[1], p[2])
        let i = e.next() * 200
        let a = e.next() * 200
        let dcx = 40 + e.next() * 120
        let dcy = 40 + e.next() * 120
        let dr = 36 + e.next() * 30
        var out = [bg(t), circle(f(dcx), f(dcy), f(dr), fill: r)]
        for row in 0..<13 {
            for col in 0..<13 {
                let x = 8 + Double(col) * 15.5
                let y = 8 + Double(row) * 15.5
                let c = hypot(x - i, y - a) / 260
                let l = max(0.8, 7.4 * (1 - c * 1.15))
                out.append(circle(f(x), f(y), f(l), fill: n))
            }
        }
        return out
    }

    private static func arcs(_ e: inout SeededRandom, _ p: [String]) -> [ArtPrimitive] {
        let (t, n, r, i) = (p[0], p[1], p[2], p[3])
        let o = [n, r, i, n]
        var out = [bg(t)]
        for k in 0..<4 {
            let x = Double(k % 2 * 100)
            let y = Double(k / 2 * 100)
            let rot = Double(Int((e.next() * 4).rounded(.down)) * 90)
            let color = o[Int((e.next() * 4).rounded(.down))]
            let tile = ArtPrimitive(kind: .path, text: ["d": "M0 0H100A100 100 0 0 1 0 100Z", "fill": color])
            let dot = ArtPrimitive(kind: .circle, num: ["cx": 26, "cy": 26, "r": 13, "opacity": 0.95],
                                   text: ["fill": o[(k + 1) % 4]])
            out.append(ArtPrimitive(kind: .g,
                                    text: ["transform": "translate(\(js(x + 50)) \(js(y + 50))) rotate(\(js(rot))) translate(-50 -50)"],
                                    children: [tile, dot]))
        }
        return out
    }

    private static func blocks(_ e: inout SeededRandom, _ p: [String]) -> [ArtPrimitive] {
        let (t, n, r, i) = (p[0], p[1], p[2], p[3])
        let a = 50 + e.next() * 70
        let o = 50 + e.next() * 70
        let s = [n, r, i, t]
        let cells: [(Double, Double, Double, Double)] = [
            (0, 0, a, o), (a, 0, 200 - a, o), (0, o, a, 200 - o), (a, o, 200 - a, 200 - o),
        ]
        let u = V8RandomSort.sort([n, i, r, n]) { e.next() - 0.5 }
        var out = [bg(t)]
        for (idx, cell) in cells.enumerated() {
            out.append(ArtPrimitive(kind: .rect,
                                    num: ["x": f(cell.0), "y": f(cell.1), "width": f(cell.2), "height": f(cell.3)],
                                    text: ["fill": u[idx]]))
        }
        let radius = 28 + e.next() * 22
        let fill = s[Int((e.next() * 3).rounded(.down))]
        out.append(circle(f(a), f(o), f(radius), fill: fill, stroke: t, strokeWidth: 6))
        return out
    }

    private static func waves(_ e: inout SeededRandom, _ p: [String]) -> [ArtPrimitive] {
        let (t, n, r, i) = (p[0], p[1], p[2], p[3])
        let o = [n, r, i, n, r, i, n, r]
        let s = 6 + Int((e.next() * 2).rounded(.down))
        var out = [bg(t)]
        for k in 0..<s {
            let base = 24 + 176 / Double(s) * Double(k)
            let amp = 6 + e.next() * 14
            let phase = e.next() * 6
            let freq = 0.025 + e.next() * 0.03
            var d = "M0 200 L0 \(js(f(base)))"
            for x in stride(from: 0, through: 200, by: 5) {
                d += " L\(x) \(js(f(base + sin(Double(x) * freq * 6.28 + phase) * amp)))"
            }
            out.append(ArtPrimitive(kind: .path, num: ["opacity": 0.96], text: ["d": d + " L200 200 Z", "fill": o[k]]))
        }
        return out
    }

    private static func orbit(_ e: inout SeededRandom, _ p: [String]) -> [ArtPrimitive] {
        let (t, n, r, i) = (p[0], p[1], p[2], p[3])
        let a = 80 + e.next() * 40
        let o = 80 + e.next() * 40
        var out = [bg(t)]
        for _ in 0..<18 {
            let x = e.next() * 200
            let y = e.next() * 200
            let rad = 0.8 + e.next() * 1.4
            out.append(circle(f(x), f(y), f(rad), fill: i, opacity: 0.7))
        }
        out.append(circle(f(a), f(o), f(46 + e.next() * 16), fill: n))
        for k in 0..<3 {
            let rot = f(e.next() * 160 - 80)
            out.append(ArtPrimitive(kind: .ellipse,
                                    num: ["cx": f(a), "cy": f(o), "rx": f(80 + Double(k) * 24),
                                          "ry": f(26 + Double(k) * 12), "strokeWidth": 2, "opacity": 0.85],
                                    text: ["transform": "rotate(\(js(rot)) \(js(f(a))) \(js(f(o))))",
                                           "fill": "none", "stroke": k == 1 ? r : i]))
        }
        let mx = f(a + 70 + e.next() * 30)
        let my = f(o - 20 - e.next() * 30)
        out.append(circle(mx, my, 9, fill: r))
        return out
    }
}

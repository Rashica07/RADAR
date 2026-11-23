import SwiftUI

/// Draws generative cover art. Port of the artifact's `<Cover>`: an SVG with
/// `viewBox="0 0 200 200"` and `preserveAspectRatio="xMidYMid slice"` — the art always fills
/// the frame and the overflow is cropped.
struct ArtworkView: View {
    let spec: ArtSpec
    var label: String?

    init(_ spec: ArtSpec, label: String? = nil) {
        self.spec = spec
        self.label = label
    }

    init(key: String, label: String? = nil) {
        self.init(ArtSpec(key: key), label: label)
    }

    var body: some View {
        let primitives = ArtworkCache.primitives(for: spec)
        Canvas(rendersAsynchronously: false) { context, size in
            guard size.width > 0, size.height > 0 else { return }
            let scale = max(size.width, size.height) / ArtworkRenderer.viewBox
            var ctx = context
            ctx.clipToLayer { $0.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black)) }
            ctx.translateBy(x: (size.width - ArtworkRenderer.viewBox * scale) / 2,
                            y: (size.height - ArtworkRenderer.viewBox * scale) / 2)
            ctx.scaleBy(x: scale, y: scale)
            for primitive in primitives { ArtworkRenderer.draw(primitive, in: &ctx) }
        }
        .accessibilityElement()
        .accessibilityLabel(label ?? "")
        .accessibilityHidden(label == nil)
        .accessibilityAddTraits(label == nil ? [] : .isImage)
    }
}

/// Generated primitives are pure functions of the spec; keep them so scrolling lists don't
/// regenerate them (and `blocks` doesn't re-run its sort).
enum ArtworkCache {
    private final class Box { let value: [ArtPrimitive]; init(_ v: [ArtPrimitive]) { value = v } }
    private static let cache: NSCache<NSString, Box> = {
        let c = NSCache<NSString, Box>()
        c.countLimit = 512
        return c
    }()

    static func primitives(for spec: ArtSpec) -> [ArtPrimitive] {
        let key = "\(spec.seed)-\(spec.palette.rawValue)-\(spec.style.rawValue)" as NSString
        if let hit = cache.object(forKey: key) { return hit.value }
        let made = ArtworkPrimitives.generate(spec)
        cache.setObject(Box(made), forKey: key)
        return made
    }
}

/// Turns primitives into Canvas drawing calls (a small subset of SVG: rect, circle, ellipse,
/// path with absolute M/L/H/A/Z, line, group with translate/rotate transforms).
enum ArtworkRenderer {
    static let viewBox: CGFloat = 200

    static func draw(_ p: ArtPrimitive, in context: inout GraphicsContext) {
        let n = p.num
        let fill = color(p.text["fill"])
        let stroke = color(p.text["stroke"])
        let lineWidth = CGFloat(n["strokeWidth"] ?? 1)
        let opacity = n["opacity"] ?? 1
        let strokeOpacity = n["strokeOpacity"] ?? 1

        var shape: Path
        switch p.kind {
        case .rect:
            shape = Path(CGRect(x: n["x"] ?? 0, y: n["y"] ?? 0, width: n["width"] ?? 0, height: n["height"] ?? 0))
        case .circle:
            let r = n["r"] ?? 0
            shape = Path(ellipseIn: CGRect(x: (n["cx"] ?? 0) - r, y: (n["cy"] ?? 0) - r, width: r * 2, height: r * 2))
        case .ellipse:
            let rx = n["rx"] ?? 0, ry = n["ry"] ?? 0
            shape = Path(ellipseIn: CGRect(x: (n["cx"] ?? 0) - rx, y: (n["cy"] ?? 0) - ry, width: rx * 2, height: ry * 2))
        case .path:
            shape = SVGPathParser.path(from: p.text["d"] ?? "")
        case .line:
            shape = Path { $0.move(to: CGPoint(x: n["x1"] ?? 0, y: n["y1"] ?? 0))
                $0.addLine(to: CGPoint(x: n["x2"] ?? 0, y: n["y2"] ?? 0)) }
        case .g:
            context.drawLayer { layer in
                layer.transform = SVGTransform.parse(p.text["transform"] ?? "").concatenating(layer.transform)
                for child in p.children { draw(child, in: &layer) }
            }
            return
        }

        if let transform = p.text["transform"] {
            shape = shape.applying(SVGTransform.parse(transform))
        }

        context.drawLayer { layer in
            layer.opacity = opacity
            if let fill { layer.fill(shape, with: .color(fill)) }
            if let stroke {
                layer.stroke(shape, with: .color(stroke.opacity(strokeOpacity)), lineWidth: lineWidth)
            }
        }
    }

    static func color(_ hex: String?) -> Color? {
        guard let hex, hex.hasPrefix("#"), hex.count == 7, let v = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return Color(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
                     blue: Double(v & 0xFF) / 255, opacity: 1)
    }
}

/// `translate(a b) rotate(d [cx cy])` lists → CGAffineTransform (SVG applies left to right to the
/// coordinate system, i.e. the leftmost function is the outermost transform).
enum SVGTransform {
    static func parse(_ string: String) -> CGAffineTransform {
        var result = CGAffineTransform.identity
        var rest = Substring(string)
        while let open = rest.firstIndex(of: "("), let close = rest.firstIndex(of: ")") {
            let name = rest[rest.startIndex..<open].trimmingCharacters(in: .whitespaces)
            let args = rest[rest.index(after: open)..<close]
                .split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
            var step = CGAffineTransform.identity
            switch name {
            case "translate" where args.count >= 1:
                step = CGAffineTransform(translationX: args[0], y: args.count > 1 ? args[1] : 0)
            case "rotate" where args.count >= 1:
                let r = CGAffineTransform(rotationAngle: args[0] * .pi / 180)
                if args.count >= 3 {
                    step = CGAffineTransform(translationX: args[1], y: args[2]).rotated(by: args[0] * .pi / 180)
                        .translatedBy(x: -args[1], y: -args[2])
                } else { step = r }
            default: break
            }
            result = step.concatenating(result)   // later functions apply first to the geometry
            rest = rest[rest.index(after: close)...]
        }
        return result
    }
}

/// Absolute `M L H V A Z` only (all the artwork generators use). Circular arcs are flattened.
enum SVGPathParser {
    static func path(from d: String) -> Path {
        var path = Path()
        var tokens = tokenize(d)[...]
        var current = CGPoint.zero
        var start = CGPoint.zero
        func num() -> Double? { tokens.isEmpty ? nil : Double(tokens.removeFirst()) }

        var command: Character = "M"
        while let token = tokens.first {
            if let c = token.first, c.isLetter { command = c; tokens.removeFirst() }
            switch command {
            case "M":
                guard let x = num(), let y = num() else { return path }
                current = CGPoint(x: x, y: y); start = current; path.move(to: current); command = "L"
            case "L":
                guard let x = num(), let y = num() else { return path }
                current = CGPoint(x: x, y: y); path.addLine(to: current)
            case "H":
                guard let x = num() else { return path }
                current.x = x; path.addLine(to: current)
            case "V":
                guard let y = num() else { return path }
                current.y = y; path.addLine(to: current)
            case "A":
                guard let rx = num(), num() != nil, num() != nil, let large = num(), let sweep = num(),
                      let x = num(), let y = num() else { return path }
                let end = CGPoint(x: x, y: y)
                addArc(&path, from: current, to: end, radius: rx, large: large != 0, sweep: sweep != 0)
                current = end
            case "Z", "z":
                path.closeSubpath(); current = start
            default:
                return path
            }
        }
        return path
    }

    private static func tokenize(_ d: String) -> [String] {
        var out: [String] = []
        var number = ""
        func flush() { if !number.isEmpty { out.append(number); number = "" } }
        for ch in d {
            if ch.isLetter { flush(); out.append(String(ch)) }
            else if ch == " " || ch == "," { flush() }
            else if ch == "-" { flush(); number = "-" }
            else { number.append(ch) }
        }
        flush()
        return out
    }

    /// SVG endpoint-to-centre conversion for a circular arc, flattened to short segments.
    private static func addArc(_ path: inout Path, from p1: CGPoint, to p2: CGPoint,
                               radius: Double, large: Bool, sweep: Bool) {
        var r = abs(radius)
        let dx = (p1.x - p2.x) / 2, dy = (p1.y - p2.y) / 2
        let d2 = dx * dx + dy * dy
        guard d2 > 0, r > 0 else { path.addLine(to: p2); return }
        if r * r < d2 { r = d2.squareRoot() }
        let coef = (max(0, (r * r - d2) / d2)).squareRoot() * (large == sweep ? -1 : 1)
        let cxp = coef * dy, cyp = -coef * dx
        let cx = cxp + (p1.x + p2.x) / 2, cy = cyp + (p1.y + p2.y) / 2
        let t1 = atan2((dy - cyp) / r, (dx - cxp) / r)
        let t2 = atan2((-dy - cyp) / r, (-dx - cxp) / r)
        var delta = t2 - t1
        if !sweep, delta > 0 { delta -= 2 * .pi }
        if sweep, delta < 0 { delta += 2 * .pi }
        let steps = max(2, Int((abs(delta) / (.pi / 60)).rounded(.up)))
        for k in 1...steps {
            let a = t1 + delta * Double(k) / Double(steps)
            path.addLine(to: CGPoint(x: cx + r * cos(a), y: cy + r * sin(a)))
        }
    }
}

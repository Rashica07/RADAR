import SwiftUI
import XCTest
@testable import RADAR

/// Compares the Swift cover generators with `ArtVectors.json`, produced by running the
/// ORIGINAL artifact generators in V8 (`tools/gen-art-vectors.js`).
final class ArtworkTests: XCTestCase {
    private struct Vectors: Decodable { let cases: [Case] }
    private struct Case: Decodable {
        let seed: UInt32, palette: String, style: String
        let prims: [JSPrim]
    }
    /// A JS primitive: `type`, `children`, and every other key as a loosely typed value.
    private struct JSPrim: Decodable {
        let type: String
        var values: [String: JSValue] = [:]
        var children: [JSPrim] = []
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: AnyKey.self)
            type = try c.decode(String.self, forKey: AnyKey("type"))
            for key in c.allKeys where key.stringValue != "type" {
                if key.stringValue == "children" { children = try c.decode([JSPrim].self, forKey: key) }
                else { values[key.stringValue] = try c.decode(JSValue.self, forKey: key) }
            }
        }
    }
    private enum JSValue: Decodable {
        case number(Double), text(String)
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let d = try? c.decode(Double.self) { self = .number(d) } else { self = .text(try c.decode(String.self)) }
        }
    }
    private struct AnyKey: CodingKey {
        var stringValue: String; var intValue: Int? { nil }
        init(_ s: String) { stringValue = s }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    private static let numericKeys: Set<String> = ["cx", "cy", "r", "rx", "ry", "x", "y", "x1", "y1", "x2", "y2",
                                                   "width", "height", "opacity", "strokeOpacity", "strokeWidth"]

    private func load() throws -> Vectors {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "ArtVectors", withExtension: "json"))
        return try JSONDecoder().decode(Vectors.self, from: Data(contentsOf: url))
    }

    private func compare(_ swift: ArtPrimitive, _ js: JSPrim, _ label: String) {
        XCTAssertEqual(swift.kind.rawValue, js.type, label)
        var expectedNum: [String: Double] = [:], expectedText: [String: String] = [:]
        for (key, value) in js.values {
            switch value {
            case .number(let d): expectedNum[key] = d
            case .text(let s):
                if Self.numericKeys.contains(key), let d = Double(s) { expectedNum[key] = d } else { expectedText[key] = s }
            }
        }
        XCTAssertEqual(Set(swift.num.keys), Set(expectedNum.keys), "\(label) numeric keys")
        for (key, want) in expectedNum {
            XCTAssertEqual(swift.num[key] ?? .nan, want, accuracy: 1e-9, "\(label) \(key)")
        }
        XCTAssertEqual(swift.text, expectedText, label)
        XCTAssertEqual(swift.children.count, js.children.count, "\(label) children")
        for (i, pair) in zip(swift.children, js.children).enumerated() { compare(pair.0, pair.1, "\(label)/\(i)") }
    }

    func testAllStylesMatchTheJavaScriptGenerators() throws {
        let vectors = try load()
        XCTAssertEqual(vectors.cases.count, 48)
        XCTAssertEqual(Set(vectors.cases.map(\.style)), Set(ArtStyle.allCases.map(\.rawValue)))
        for c in vectors.cases {
            let spec = ArtSpec(seed: c.seed, palette: ArtPalette(rawValue: c.palette)!, style: ArtStyle(rawValue: c.style)!)
            let made = ArtworkPrimitives.generate(spec)
            let label = "\(c.style)/\(c.palette)/\(c.seed)"
            XCTAssertEqual(made.count, c.prims.count, label)
            for (i, pair) in zip(made, c.prims).enumerated() { compare(pair.0, pair.1, "\(label)#\(i)") }
        }
    }

    func testNumberFormattingMatchesJavaScript() {
        XCTAssertEqual(ArtworkPrimitives.js(150), "150")
        XCTAssertEqual(ArtworkPrimitives.js(70.7), "70.7")
        XCTAssertEqual(ArtworkPrimitives.js(-5.5), "-5.5")
        XCTAssertEqual(ArtworkPrimitives.js(-0.0), "0")
        XCTAssertEqual(ArtworkPrimitives.f(-0.04), 0)          // JS Math.round(-0.4)/10 → -0
        XCTAssertEqual(ArtworkPrimitives.f(2.25), 2.3)         // half rounds up
        XCTAssertEqual(ArtworkPrimitives.f(-2.25), -2.2)       // JS rounds -22.5 up to -22
        XCTAssertEqual(ArtworkPrimitives.hexString(0x2B1410), "#2B1410")
    }

    /// Sequences recorded from real V8: `["A","B","C","D"].sort(scriptedComparator)`.
    func testV8RandomSortMatchesRecordedV8Runs() {
        let cases: [([Double], String, Int)] = [
            ([-1, -1, -1, -1, -1], "DCBA", 5), ([1, -1, -1, -1, -1], "DCAB", 5),
            ([-1, 1, -1, -1], "DBAC", 4), ([1, 1, -1, -1], "DABC", 4),
            ([-1, -1, 1, -1, -1], "DBCA", 5), ([-1, 1, 1, -1], "BADC", 4),
            ([1, 1, 1, 1], "ABCD", 4), ([-1, -1, -1, 1, -1], "CBDA", 5),
            ([1, -1, 1, 1, -1], "ACDB", 5),
        ]
        for (values, expected, calls) in cases {
            var i = 0
            let sorted = V8RandomSort.sort(["A", "B", "C", "D"]) { defer { i += 1 }; return values[i] * 0.3 }
            XCTAssertEqual(sorted.joined(), expected, "\(values)")
            XCTAssertEqual(i, calls, "comparator calls for \(values)")
        }
        XCTAssertEqual(V8RandomSort.sort([1]) { XCTFail("no compare for one element"); return 0 }, [1])
        XCTAssertEqual(V8RandomSort.sort([Int]()) { 0 }, [])
    }

    func testSpecIsDeterministicAndCached() {
        let spec = ArtSpec(key: "ottobre")
        XCTAssertEqual(ArtworkPrimitives.generate(spec), ArtworkPrimitives.generate(spec))
        XCTAssertEqual(ArtworkCache.primitives(for: spec), ArtworkPrimitives.generate(spec))
    }

    func testSVGTransformsAndPaths() {
        let t = SVGTransform.parse("translate(50 50) rotate(90) translate(-50 -50)")
        let p = CGPoint(x: 0, y: 0).applying(t)                 // (0,0) → rotate 90° about (50,50) → (100,0)
        XCTAssertEqual(p.x, 100, accuracy: 1e-9); XCTAssertEqual(p.y, 0, accuracy: 1e-9)
        let r = CGPoint(x: 10, y: 0).applying(SVGTransform.parse("rotate(90 0 0)"))
        XCTAssertEqual(r.x, 0, accuracy: 1e-9); XCTAssertEqual(r.y, 10, accuracy: 1e-9)

        let quarter = SVGPathParser.path(from: "M0 0H100A100 100 0 0 1 0 100Z")
        let bounds = quarter.boundingRect
        XCTAssertEqual(bounds.minX, 0, accuracy: 1e-6); XCTAssertEqual(bounds.maxX, 100, accuracy: 1e-6)
        XCTAssertEqual(bounds.minY, 0, accuracy: 1e-6); XCTAssertEqual(bounds.maxY, 100, accuracy: 1e-6)
        XCTAssertTrue(quarter.contains(CGPoint(x: 20, y: 20)))      // inside the quarter disc tile
        XCTAssertFalse(quarter.contains(CGPoint(x: 95, y: 95)))
    }

    @MainActor
    func testEveryStyleRendersDistinctPixels() throws {
        for style in ArtStyle.allCases {
            let view = ArtworkView(ArtSpec(seed: 12345, palette: .ember, style: style)).frame(width: 120, height: 80)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            let image = try XCTUnwrap(renderer.cgImage, "\(style)")
            XCTAssertEqual(image.width, 120); XCTAssertEqual(image.height, 80)
            let data = try XCTUnwrap(image.dataProvider?.data as Data?)
            var colours = Set<[UInt8]>()
            for i in stride(from: 0, to: data.count - 3, by: 4 * 7) { colours.insert(Array(data[i..<i + 3])) }
            XCTAssertGreaterThan(colours.count, 1, "\(style) rendered one flat colour")
        }
    }
}

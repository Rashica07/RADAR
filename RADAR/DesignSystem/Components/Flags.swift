import Charts
import SwiftUI

/// `.flag--new`
struct NewFlag: View {
    var body: some View {
        Text("New").font(RadarFont.display(12, .black, relativeTo: .caption)).tracking(12 * 0.1).textCase(.uppercase)
            .foregroundStyle(Color.radarOnSignal).fixedSize()
            .padding(.top, 3).padding(.bottom, 2).padding(.horizontal, 6)
            .background(Color.radarSignal)
    }
}

/// `.flag--e`: 14 pt square "E".
struct ExplicitFlag: View {
    var body: some View {
        Text("E").font(RadarFont.ui(9, .bold, relativeTo: .caption2)).foregroundStyle(Color.radarText2)
            .frame(width: 14, height: 14).background(Color.radarSurface3)
            .accessibilityLabel("Explicit")
    }
}

/// `.demo-badge`: "Demo data" with a signal dot; tappable when `action` is set ("About demo data").
struct DemoBadge: View {
    var action: (() -> Void)?
    var body: some View {
        if let action {
            Button(action: action) { label }.buttonStyle(.plain).accessibilityLabel("About demo data")
        } else {
            label
        }
    }
    private var label: some View {
        HStack(spacing: 7) {
            Circle().fill(Color.radarSignal).frame(width: 6, height: 6)
            Text("Demo data").font(RadarFont.ui(10, .bold, relativeTo: .caption2)).tracking(10 * 0.14).textCase(.uppercase)
        }
        .foregroundStyle(Color.radarText2)
        .padding(.horizontal, 10).frame(minHeight: 28)
        .overlay { Rectangle().strokeBorder(Color.radarLineStrong, lineWidth: 1) }
        .frame(minHeight: action == nil ? 28 : RadarScale.touch)     // tappable badge gets a 44 pt target
    }
}

/// `.source-tag`: plug (or file for local) icon + provider name.
struct SourceTag: View {
    let source: TrackSource
    let name: String
    var body: some View {
        HStack(spacing: 8) {
            RadarIcon(source == .local ? .file : .plug, size: 14)
            Text(name).font(RadarFont.ui(13, .semibold, relativeTo: .footnote))
        }
        .foregroundStyle(Color.radarText2)
    }
}

// MARK: - Download status

extension DownloadStatus {
    enum Tone: Sendable { case ok, off }
    /// Same table as the artifact's `Mi`.
    var presentation: (icon: RadarIconName, label: String, sub: String, tone: Tone) {
        switch self {
        case .available: (.download, "Download available", "Artist-authorized · demo status", .ok)
        case .downloaded: (.check, "Downloaded", "Stored for offline listening · demo", .ok)
        case .streamingOnly: (.info, "Streaming only", "The rights holder has not enabled downloads", .off)
        case .unavailable: (.lock, "Not available here", "Restricted in your selected country · demo", .off)
        case .local: (.file, "On this device", "Local file · never uploaded", .ok)
        }
    }
}

/// `.status`
struct StatusLabel: View {
    let status: DownloadStatus
    var body: some View {
        let p = status.presentation
        HStack(spacing: 7) {
            RadarIcon(p.icon, size: 15)
            Text(p.label).font(RadarFont.ui(12, .bold, relativeTo: .caption)).tracking(12 * 0.1).textCase(.uppercase)
                .lineLimit(1).fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(p.tone == .ok ? Color.radarAccentText : Color.radarText2)
    }
}

// MARK: - Chart movement

/// Chart movement versus the previous window (`Fi` in the artifact).
enum ChartMove: Equatable, Sendable {
    case new, up(Int), down(Int), unchanged

    init(delta: Int, previous: Int?) {
        if previous == nil { self = .new }
        else if delta > 0 { self = .up(delta) }
        else if delta < 0 { self = .down(-delta) }
        else { self = .unchanged }
    }

    var accessibilityLabel: String {
        switch self {
        case .new: "New entry"
        case .up(let n): "Up \(n) \(n == 1 ? "place" : "places")"
        case .down(let n): "Down \(n) \(n == 1 ? "place" : "places")"
        case .unchanged: "Unchanged"
        }
    }
}

struct MoveIndicator: View {
    let move: ChartMove
    init(_ move: ChartMove) { self.move = move }
    init(delta: Int, previous: Int?) { move = ChartMove(delta: delta, previous: previous) }

    var body: some View {
        Group {
            switch move {
            case .new:
                Text("NEW").font(RadarFont.display(11, .black, relativeTo: .caption2)).tracking(11 * 0.1)
                    .foregroundStyle(Color.radarOnSignal).fixedSize().padding(.top, 3).padding(.bottom, 2).padding(.horizontal, 5)
                    .background(Color.radarSignal)
            case .up(let n): arrow(.up, n, Color.radarSignalText)
            case .down(let n): arrow(.down, n, Color.radarText3)
            case .unchanged: Text("—").font(RadarFont.ui(12, .bold)).foregroundStyle(Color.radarText3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(move.accessibilityLabel)
    }

    private func arrow(_ icon: RadarIconName, _ n: Int, _ color: Color) -> some View {
        HStack(spacing: 3) {
            RadarIcon(icon, size: 10)
            Text("\(n)").font(RadarFont.ui(12, .bold)).monospacedDigit()
        }
        .foregroundStyle(color)
    }
}

// MARK: - Sparkline

/// Tiny trend line built on Swift Charts: no axes, a dot on the latest value, mint when rising.
struct Sparkline: View {
    var data: [Double]
    var up = true
    var width: CGFloat = 72
    var height: CGFloat = 24

    /// The vertical range with a little air so the line and dot never touch the frame.
    static func domain(_ data: [Double]) -> ClosedRange<Double> {
        guard let lo = data.min(), let hi = data.max() else { return 0...1 }
        let span = hi - lo == 0 ? 1 : hi - lo
        return (lo - span * 0.17)...(hi + span * 0.17)
    }

    var body: some View {
        let color = up ? Color.radarSignalText : Color.radarText3
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { i, v in
                LineMark(x: .value("Day", i), y: .value("Plays", v))
                    .foregroundStyle(color).lineStyle(StrokeStyle(lineWidth: 1.8, lineJoin: .miter))
                    .interpolationMethod(.linear)
            }
            if let last = data.indices.last {
                PointMark(x: .value("Day", last), y: .value("Plays", data[last]))
                    .foregroundStyle(color).symbolSize(26)
            }
        }
        .chartXAxis(.hidden).chartYAxis(.hidden)
        .chartYScale(domain: Self.domain(data))
        .chartLegend(.hidden)
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

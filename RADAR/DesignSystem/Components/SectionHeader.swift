import SwiftUI

/// `.sh`: index · hairline rule · readout · link, then a big display title and optional sub-line.
struct SectionHeader: View {
    struct Action { let label: String; let perform: () -> Void }

    var title: String
    var idx: String?
    var kicker: String?
    var moving = false
    var sub: String?
    var loading = false
    var large = false
    var action: Action?
    @ScaledMetric(relativeTo: .largeTitle) private var scale = 1

    init(_ title: String, idx: String? = nil, kicker: String? = nil, moving: Bool = false, sub: String? = nil,
         loading: Bool = false, large: Bool = false, action: Action? = nil) {
        self.title = title; self.idx = idx; self.kicker = kicker; self.moving = moving
        self.sub = sub; self.loading = loading; self.large = large; self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                if let idx {
                    Text(idx).font(RadarFont.ui(11, .bold, relativeTo: .caption2)).tracking(11 * 0.14)
                        .monospacedDigit().foregroundStyle(Color.radarAccentText).accessibilityHidden(true)
                }
                Rectangle().fill(Color.radarLineStrong).frame(height: 1).accessibilityHidden(true)
                if loading {
                    AcquiringSignal()
                } else if let kicker {
                    HStack(spacing: 8) {
                        if moving { PingBlip(size: 6) }
                        Text(kicker).radarReadout(moving ? .radarSignalText : .radarText3)
                    }
                }
                if let action {
                    Button(action: action.perform) {
                        HStack(spacing: 2) {
                            Text(action.label).font(RadarFont.ui(13, .semibold)).foregroundStyle(Color.radarAccentText)
                            RadarIcon(.chevronRight, size: 14).foregroundStyle(Color.radarAccentText)
                        }
                        .frame(minHeight: RadarScale.touch)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(minHeight: 28)

            TitleText(title: title, large: large)

            if let sub {
                Text(sub).font(RadarFont.body(15)).foregroundStyle(Color.radarText2).padding(.top, 2)
            }
        }
        .padding(.bottom, 14)
        .accessibilityElement(children: .contain)
    }

    private struct TitleText: View {
        let title: String
        let large: Bool
        @Environment(\.radarScreenWidth) private var width
        var body: some View {
            let size = large ? RadarScale.displayL(width) : RadarScale.displayM(width)
            Text(title).font(RadarFont.display(size, .black)).textCase(.uppercase)
                .lineSpacing(0).foregroundStyle(Color.radarText)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

/// "Acquiring signal" with a blinking block caret (`.acq`).
struct AcquiringSignal: View {
    @Environment(\.accessibilityReduceMotion) private var reduce
    var body: some View {
        HStack(spacing: 8) {
            Text("Acquiring signal").font(RadarFont.ui(11, .semibold, relativeTo: .caption2))
                .tracking(11 * 0.14).textCase(.uppercase)
            TimelineView(.periodic(from: .now, by: 0.45)) { tl in
                let on = reduce || Int(tl.date.timeIntervalSinceReferenceDate / 0.45) % 2 == 0
                Rectangle().frame(width: 7, height: 12).opacity(on ? 1 : 0)
            }
        }
        .foregroundStyle(Color.radarAccentText)
        .accessibilityLabel("Loading")
    }
}

private struct ScreenWidthKey: EnvironmentKey { static let defaultValue: CGFloat = 393 }
extension EnvironmentValues {
    /// Width the fluid type scale is computed against (the app shell sets it from the window).
    var radarScreenWidth: CGFloat {
        get { self[ScreenWidthKey.self] }
        set { self[ScreenWidthKey.self] = newValue }
    }
}

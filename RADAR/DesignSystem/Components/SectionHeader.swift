import SwiftUI

/// Opens a screen section: index and rule on a thin top line, an optional live readout and "see all"
/// link, then the big title and a sentence of context.
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

    init(_ title: String, idx: String? = nil, kicker: String? = nil, moving: Bool = false, sub: String? = nil,
         loading: Bool = false, large: Bool = false, action: Action? = nil) {
        self.title = title; self.idx = idx; self.kicker = kicker; self.moving = moving
        self.sub = sub; self.loading = loading; self.large = large; self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            topLine
            Text(title).radarTitle(large ? .large : .medium)
                .foregroundStyle(Color.radarText)
                .accessibilityAddTraits(.isHeader)
            if let sub {
                Text(sub).font(RadarFont.body(15, .regular, relativeTo: .subheadline)).foregroundStyle(Color.radarText2)
                    .padding(.top, 2)
            }
        }
        .padding(.bottom, 14)
        .accessibilityElement(children: .contain)
    }

    private var topLine: some View {
        HStack(spacing: 12) {
            if let idx {
                Text(idx).font(RadarFont.ui(11, .bold, relativeTo: .caption2)).tracking(1.5)
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
                        Text(action.label).font(RadarFont.ui(13, .semibold, relativeTo: .footnote))
                        RadarIcon(.chevronRight, size: 14)
                    }
                    .foregroundStyle(Color.radarAccentText)
                    .frame(minHeight: RadarScale.touch)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(minHeight: 28)
    }
}

/// "Acquiring signal" with a blinking block caret.
struct AcquiringSignal: View {
    @Environment(\.accessibilityReduceMotion) private var reduce
    var body: some View {
        HStack(spacing: 8) {
            Text("Acquiring signal").font(RadarFont.ui(11, .semibold, relativeTo: .caption2))
                .tracking(1.5).textCase(.uppercase)
            Rectangle().frame(width: 7, height: 12)
                .phaseAnimator(reduce ? [1.0] : [1.0, 0.0]) { caret, opacity in
                    caret.opacity(opacity)
                } animation: { _ in .linear(duration: 0.01).delay(0.45) }
        }
        .foregroundStyle(Color.radarAccentText)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

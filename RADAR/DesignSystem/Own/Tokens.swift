import SwiftUI

/// RADAR's own small kit: custom controls built from SwiftUI primitives that still read as native
/// (system font and symbols, materials, hairline borders, springs). Same idea as Spindare's kit.
enum RadarUI {
    /// Depth comes from hairlines, not shadows.
    enum Hairline {
        static func color(_ scheme: ColorScheme, emphasis: Double = 1) -> Color {
            scheme == .dark ? Color.white.opacity(0.10 * emphasis) : Color.black.opacity(0.07 * emphasis)
        }
        static let width: CGFloat = 1
    }

    /// Two feels, used everywhere: `settle` for things that react to a finger, `layer` for screens.
    @MainActor
    enum Motion {
        static var settle: Animation { resolve(.spring(response: 0.35, dampingFraction: 0.85)) }
        static var page: Animation { resolve(.spring(response: 0.42, dampingFraction: 0.9)) }
        static var layer: Animation { resolve(.spring(response: 0.36, dampingFraction: 1.0)) }

        static func resolve(_ animation: Animation) -> Animation {
            UIAccessibility.isReduceMotionEnabled ? .easeOut(duration: 0.18) : animation
        }
    }
}

extension View {
    /// Material plate with a hairline edge.
    func radarGlass<S: InsettableShape>(_ shape: S, scheme: ColorScheme) -> some View {
        background(.bar, in: shape)
            .overlay(shape.strokeBorder(RadarUI.Hairline.color(scheme, emphasis: 1.2), lineWidth: RadarUI.Hairline.width))
    }
}

extension ArtPalette {
    /// A deep version of the palette's main colour: dark enough for white text on top of it.
    var tint: Color {
        let hex = self.hex[1]
        let r = Double((hex >> 16) & 0xFF) / 255, g = Double((hex >> 8) & 0xFF) / 255, b = Double(hex & 0xFF) / 255
        return Color(red: r * 0.45, green: g * 0.45, blue: b * 0.45)
    }
}

/// Fraction maths for the scrubber, kept pure so it can be tested.
enum ScrubBarMath {
    static func fraction(x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return Double(min(max(x / width, 0), 1))
    }
}

/// Thin seek bar. A bare capsule at rest; it thickens and shows a knob while the finger is on it.
/// Pressing anywhere jumps there; the seek commits on release. VoiceOver can adjust it in steps.
struct ScrubBar: View {
    let fraction: Double
    var onChange: (Double) -> Void = { _ in }
    var onCommit: (Double) -> Void

    @GestureState private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let f = min(max(fraction, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.25))
                Capsule().fill(.white).frame(width: max(w * f, 0))
                Circle().fill(.white).frame(width: 14, height: 14)
                    .offset(x: w * f - 7)
                    .opacity(isDragging ? 1 : 0)
            }
            .frame(height: isDragging ? 8 : 4)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, state, _ in state = true }
                    .onChanged { onChange(ScrubBarMath.fraction(x: $0.location.x, width: w)) }
                    .onEnded { onCommit(ScrubBarMath.fraction(x: $0.location.x, width: w)) }
            )
            .animation(reduceMotion ? nil : RadarUI.Motion.settle, value: isDragging)
        }
        .frame(height: 28)
        .accessibilityElement()
        .accessibilityLabel("Playback position")
        .accessibilityValue("\(Int(fraction * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onCommit(min(1, fraction + 0.05))
            case .decrement: onCommit(max(0, fraction - 0.05))
            @unknown default: break
            }
        }
    }
}

/// The app's tab bar: a rounded plate floating above the bottom edge. The active tab's icon becomes
/// a mint circle that lifts out of the bar like a bubble; switching tabs rolls the bubble across
/// on a slightly bouncy spring while the icon swaps. Built from primitives, not the system bar.
struct RadarTabBar<Tab: Hashable & CaseIterable>: View where Tab.AllCases: RandomAccessCollection {
    @Binding var selection: Tab
    let title: (Tab) -> String
    let symbol: (Tab) -> String
    var onReselect: (Tab) -> Void = { _ in }

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let barHeight: CGFloat = 62
    private let bubble: CGFloat = 54
    private let lift: CGFloat = 22

    private var tabs: [Tab] { Array(Tab.allCases) }
    private var index: Int { tabs.firstIndex(of: selection) ?? 0 }

    var body: some View {
        GeometryReader { geo in
            let slot = geo.size.width / CGFloat(max(tabs.count, 1))
            ZStack(alignment: .topLeading) {
                // The plate.
                RoundedRectangle(cornerRadius: 31, style: .continuous)
                    .fill(.bar)
                    .overlay(RoundedRectangle(cornerRadius: 31, style: .continuous)
                        .strokeBorder(RadarUI.Hairline.color(scheme, emphasis: 1.4), lineWidth: RadarUI.Hairline.width))
                    .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
                    .frame(height: barHeight)
                    .offset(y: lift)

                // Slots: inactive tabs show icon + label; the active one leaves room for the bubble.
                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { i, tab in
                        let on = i == index
                        Button {
                            if on { onReselect(tab) } else { withAnimation(bubbleSpring) { selection = tab } }
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: symbol(tab)).font(.system(size: 19, weight: .semibold))
                                    .frame(height: 24).opacity(on ? 0 : 1)
                                Text(title(tab)).font(.system(size: 10.5, weight: .semibold))
                            }
                            .foregroundStyle(on ? Color.radarAccentText : Color.secondary)
                            .frame(width: slot, height: barHeight)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(title(tab))
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
                .offset(y: lift + 6)

                // The bubble: a mint circle, ringed in the page colour so it reads as cut out of the bar.
                Circle()
                    .fill(Color.radarAccent)
                    .overlay(Circle().strokeBorder(Color.radarBg, lineWidth: 5).padding(-5))
                    .overlay(
                        Image(systemName: symbol(selection))
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(Color.radarOnAccent)
                            .contentTransition(.symbolEffect(.replace))
                    )
                    .frame(width: bubble, height: bubble)
                    .shadow(color: Color.radarAccent.opacity(0.35), radius: 10, y: 4)
                    .offset(x: slot * (CGFloat(index) + 0.5) - bubble / 2, y: 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: barHeight + lift)
        .padding(.horizontal, 14)
        .padding(.bottom, 2)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var bubbleSpring: Animation {
        reduceMotion ? .easeOut(duration: 0.18) : .spring(response: 0.42, dampingFraction: 0.72)
    }
}

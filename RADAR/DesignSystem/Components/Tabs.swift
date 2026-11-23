import SwiftUI

/// `.tabs`: uppercase labels with optional counts, a hairline underneath, and a 3 pt accent "ink"
/// that slides (0.38 s ease-out) to the selected tab. Scrolls sideways and fades at the edge.
struct RadarTabs<Value: Hashable>: View {
    struct Item: Identifiable {
        let value: Value
        let label: String
        var count: Int?
        var id: Value { value }
        init(_ value: Value, _ label: String, count: Int? = nil) { self.value = value; self.label = label; self.count = count }
    }

    let items: [Item]
    @Binding var selection: Value
    var compact = false                         // `.tabs--mute`: 40 pt tall instead of 46
    @Namespace private var inkSpace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(items) { item in
                    let selected = item.value == selection
                    Button { selection = item.value } label: {
                        HStack(spacing: 6) {
                            Text(item.label)
                            if let n = item.count { Text("\(n)").monospacedDigit().foregroundStyle(Color.radarText3) }
                        }
                        .font(RadarFont.ui(12, .bold, relativeTo: .caption))
                        .tracking(12 * 0.14).textCase(.uppercase)
                        .foregroundStyle(selected ? Color.radarText : Color.radarText3)
                        .frame(minHeight: compact ? 44 : 46)       // never below the 44 pt touch target
                        .fixedSize()
                        .overlay(alignment: .bottom) {
                            if selected {
                                Rectangle().fill(Color.radarAccent).frame(height: 3)
                                    .matchedGeometryEffect(id: "ink", in: inkSpace)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.38), value: selection)
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Color.radarLine).frame(height: 1).allowsHitTesting(false) }
        .mask(
            LinearGradient(stops: [.init(color: .black, location: 0.92), .init(color: .clear, location: 1)],
                           startPoint: .leading, endPoint: .trailing)
        )
    }
}

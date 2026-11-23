import SwiftUI

/// Segmented text tabs with counts. The accent ink glides to the selected tab with a spring, the
/// selected tab scrolls into view, and each change ticks. Scrolls sideways when the labels don't fit.
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
    @Namespace private var inkSpace
    @ScaledMetric(relativeTo: .footnote) private var height: CGFloat = 46

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in tab(item) }
                }
                .padding(.horizontal, RadarScale.gutter)
            }
            .onChange(of: selection) { _, new in
                withAnimation(.snappy) { proxy.scrollTo(new, anchor: .center) }
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Color.radarLine).frame(height: 1).allowsHitTesting(false) }
        .sensoryFeedback(.selection, trigger: selection) { _, _ in Haptics.isEnabled }
    }

    private func tab(_ item: Item) -> some View {
        let selected = item.value == selection
        return Button {
            withAnimation(.snappy(duration: 0.35)) { selection = item.value }
        } label: {
            HStack(spacing: 6) {
                Text(item.label)
                if let n = item.count { Text("\(n)").monospacedDigit().foregroundStyle(Color.radarText3) }
            }
            .font(RadarFont.ui(12, .bold, relativeTo: .caption)).tracking(1.7).textCase(.uppercase)
            .foregroundStyle(selected ? Color.radarText : Color.radarText3)
            .frame(minHeight: max(height, RadarScale.touch)).fixedSize()
            .overlay(alignment: .bottom) {
                if selected {
                    Rectangle().fill(Color.radarAccent).frame(height: 3)
                        .matchedGeometryEffect(id: "ink", in: inkSpace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id(item.value)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

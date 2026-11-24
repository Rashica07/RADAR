import SwiftUI

/// Bottom navigation (compact width). Four tabs; the active one is inked mint with a bar that
/// glides between tabs on a spring.
struct BottomNav: View {
    @Environment(AppRouter.self) private var router
    @Namespace private var bar

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let on = router.selected == tab
                Button { withAnimation(.snappy(duration: 0.32)) { router.select(tab) } } label: {
                    VStack(spacing: 4) {
                        RadarIcon(on ? tab.activeIcon : tab.icon, size: 24)
                        Text(tab.title).font(RadarFont.ui(10.5, .semibold, relativeTo: .caption2)).lineLimit(1)
                    }
                    .foregroundStyle(on ? Color.radarAccentText : Color.radarText3)
                    .frame(maxWidth: .infinity, minHeight: RadarScale.touch + 14)
                    .overlay(alignment: .top) {
                        if on { Rectangle().fill(Color.radarAccent).frame(height: 2).matchedGeometryEffect(id: "bar", in: bar) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(NavPressStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
        }
        .background(Color.radarNavBg.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Color.radarLine).frame(height: 1) }
        .sensoryFeedback(.selection, trigger: router.selected) { _, _ in Haptics.isEnabled }
    }
}

/// Rail (icons) or sidebar (icons + labels) for wider windows.
struct SideNav: View {
    let showsLabels: Bool
    @Environment(AppRouter.self) private var router
    @Namespace private var bar

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let on = router.selected == tab
                Button { withAnimation(.snappy(duration: 0.32)) { router.select(tab) } } label: {
                    HStack(spacing: 12) {
                        RadarIcon(on ? tab.activeIcon : tab.icon, size: 24)
                        if showsLabels { Text(tab.title).font(RadarFont.ui(15, .semibold)) }
                        if showsLabels { Spacer(minLength: 0) }
                    }
                    .foregroundStyle(on ? Color.radarAccentText : Color.radarText2)
                    .padding(.horizontal, showsLabels ? 14 : 0)
                    .frame(maxWidth: .infinity, minHeight: RadarScale.touch + 6, alignment: showsLabels ? .leading : .center)
                    .overlay(alignment: .leading) {
                        if on { Rectangle().fill(Color.radarAccent).frame(width: 2).matchedGeometryEffect(id: "bar", in: bar) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(NavPressStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .frame(width: showsLabels ? 208 : 72)
        .background(Color.radarNavBg.ignoresSafeArea())
        .overlay(alignment: .trailing) { Rectangle().fill(Color.radarLine).frame(width: 1).ignoresSafeArea() }
        .sensoryFeedback(.selection, trigger: router.selected) { _, _ in Haptics.isEnabled }
    }
}

struct NavPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

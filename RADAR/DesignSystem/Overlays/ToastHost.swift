import SwiftUI

/// Renders `ToastCenter.current` above everything, just over the bottom chrome.
/// - Enters at 0.97 scale + fade + a short rise (never from scale 0); leaves the way it came.
/// - Follows a downward drag 1:1, and on release hands off to a spring that keeps the flick's
///   velocity; a fast or far enough flick dismisses, otherwise it springs back. It can be
///   grabbed mid-flight because a spring always re-targets from the live offset.
/// - Announced to VoiceOver; Reduce Motion swaps movement for a plain fade.
struct ToastHost: ViewModifier {
    let center: ToastCenter
    var bottomInset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = center.current {
                    ToastView(toast: toast)
                        .offset(y: max(drag, rubber(drag)))
                        .gesture(dismissGesture)
                        .padding(.horizontal, RadarScale.gutter)
                        .padding(.bottom, bottomInset + 12)
                        .transition(reduceMotion ? .opacity
                                    : .scale(scale: 0.97, anchor: .bottom).combined(with: .opacity).combined(with: .offset(y: 16)))
                        .id(toast.id)
                        .onAppear {
                            AccessibilityNotification.Announcement(toast.message).post()
                        }
                }
            }
            .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.4, bounce: 0), value: center.current)
    }

    /// Upward drags resist instead of following (it has nowhere to go).
    private func rubber(_ d: CGFloat) -> CGFloat { d < 0 ? -(abs(d) * 0.25) : d }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { drag = $0.translation.height }
            .onEnded { value in
                // Project where the flick is heading, like scroll deceleration does.
                let projected = value.translation.height + value.velocity.height * 0.12
                if projected > 40 {
                    center.dismiss()
                    drag = 0
                } else {
                    withAnimation(.interpolatingSpring(duration: 0.4, bounce: 0, initialVelocity: Double(value.velocity.height / max(abs(drag), 1)))) { drag = 0 }
                }
            }
    }
}

private struct ToastView: View {
    let toast: ToastCenter.Toast
    var body: some View {
        HStack(spacing: 10) {
            if let icon = toast.icon {
                RadarIcon(icon, size: 18).foregroundStyle(Color.radarAccentText).accessibilityHidden(true)
            }
            Text(toast.message)
                .font(RadarFont.ui(14, .semibold, relativeTo: .subheadline))
                .foregroundStyle(Color.radarText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: 480, alignment: .leading)
        .background(Color.radarSurface3)
        .overlay { Rectangle().strokeBorder(Color.radarLineStrong, lineWidth: 1) }
        .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
    }
}

extension View {
    func toastHost(_ center: ToastCenter, bottomInset: CGFloat = 0) -> some View {
        modifier(ToastHost(center: center, bottomInset: bottomInset))
    }
}

import Foundation

/// String formatting shared by every screen. Each function mirrors a helper in the
/// Phase 01 artifact so copy and numbers read identically.
enum Format {
    /// `214` → `3:34`
    static func time(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }

    /// `4_120_000` → `4.1M`, `880_000` → `880K`, `1_480` → `1.5K`
    static func compact(_ value: Int) -> String {
        func trim(_ s: String) -> String { s.hasSuffix(".0") ? String(s.dropLast(2)) : s }
        if value >= 1_000_000 {
            let digits = value >= 10_000_000 ? 0 : 1
            return trim(String(format: "%.\(digits)f", Double(value) / 1_000_000)) + "M"
        }
        if value >= 1_000 {
            let digits = value >= 100_000 ? 0 : 1
            return trim(String(format: "%.\(digits)f", Double(value) / 1_000)) + "K"
        }
        return String(value)
    }

    /// Total running time: `1680` → `28 min`, `4000` → `1 hr 7 min`
    static func runtime(_ seconds: Double) -> String {
        let minutes = Int((seconds / 60).rounded())
        return minutes >= 60 ? "\(minutes / 60) hr \(minutes % 60) min" : "\(minutes) min"
    }

    /// Release age: `0` → `Today`, `5` → `5 days ago`, `21` → `3 wk ago`
    static func daysAgo(_ days: Int) -> String {
        if days <= 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        if days < 30 { return "\(Int((Double(days) / 7).rounded())) wk ago" }
        return "\(Int((Double(days) / 30).rounded())) mo ago"
    }

    /// Play history age, relative to `now`.
    static func playedAgo(_ date: Date, now: Date = .now) -> String {
        let minutes = Int((now.timeIntervalSince(date) / 60).rounded())
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        if minutes < 1440 { return "\(Int((Double(minutes) / 60).rounded())) hr ago" }
        return "\(Int((Double(minutes) / 1440).rounded())) d ago"
    }

    static func greeting(_ date: Date = .now) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case ..<5: return "Still up"
        case ..<12: return "Good morning"
        case ..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    /// `Monday 23 November`
    static func longDate(_ date: Date = .now) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "en_GB")))
    }

    static func megabytes(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    static func plural(_ count: Int, _ singular: String, _ plural: String? = nil) -> String {
        "\(count) " + (count == 1 ? singular : (plural ?? singular + "s"))
    }
}

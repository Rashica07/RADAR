// Generated from the RADAR Phase 01 icon set (24×24 grid, 1.75 stroke, round caps/joins).
// Regenerate with tools/icons.js — do not edit by hand.
import SwiftUI

enum RadarIconName: String, CaseIterable, Sendable {
    case discover = "discover"
    case discoverFill = "discover-fill"
    case trending = "trending"
    case search = "search"
    case library = "library"
    case settings = "settings"
    case user = "user"
    case play = "play"
    case pause = "pause"
    case next = "next"
    case prev = "prev"
    case shuffle = "shuffle"
    case `repeat` = "repeat"
    case repeatOne = "repeat-one"
    case heart = "heart"
    case heartFill = "heart-fill"
    case queue = "queue"
    case chevronDown = "chevron-down"
    case chevronLeft = "chevron-left"
    case chevronRight = "chevron-right"
    case more = "more"
    case download = "download"
    case check = "check"
    case plus = "plus"
    case x = "x"
    case clock = "clock"
    case globe = "globe"
    case file = "file"
    case note = "note"
    case up = "up"
    case down = "down"
    case share = "share"
    case speaker = "speaker"
    case speakerMute = "speaker-mute"
    case moon = "moon"
    case sun = "sun"
    case storage = "storage"
    case plug = "plug"
    case lock = "lock"
    case info = "info"
    case list = "list"
    case fullscreen = "fullscreen"
    case sparkle = "sparkle"
    case trash = "trash"
}

private func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

extension RadarIconName {
    /// Vector parts in a 24×24 coordinate space.
    var parts: [IconPart] {
        switch self {
    case .discover:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 3.0, y: 3.0, width: 18.0, height: 18.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 7.5, y: 7.5, width: 9.0, height: 9.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 12.0))
            p.addLine(to: P(18.4, 5.6))
        }
        ]
    case .discoverFill:
        return [
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.addEllipse(in: CGRect(x: 2.8, y: 2.8, width: 18.4, height: 18.4))
        },
        IconPart(fill: false, stroke: false, cut: true) { p in
            p.addEllipse(in: CGRect(x: 7.5, y: 7.5, width: 9.0, height: 9.0))
        },
        IconPart(fill: false, stroke: false, cut: true) { p in
            p.move(to: P(12.0, 12.0))
            p.addLine(to: P(18.4, 5.6))
        }
        ]
    case .trending:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(3.0, 17.0))
            p.addLine(to: P(9.5, 10.5))
            p.addLine(to: P(13.0, 14.0))
            p.addLine(to: P(21.0, 6.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(15.0, 6.0))
            p.addLine(to: P(21.0, 6.0))
            p.addLine(to: P(21.0, 12.0))
        }
        ]
    case .search:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 4.5, y: 4.5, width: 13.0, height: 13.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(20.0, 20.0))
            p.addLine(to: P(15.8, 15.8))
        }
        ]
    case .library:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(5.0, 4.0))
            p.addLine(to: P(5.0, 20.0))
            p.move(to: P(10.0, 4.0))
            p.addLine(to: P(10.0, 20.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(14.5, 5.2))
            p.addLine(to: P(19.1, 19.4))
        }
        ]
    case .settings:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.0, 7.0))
            p.addLine(to: P(14.0, 7.0))
            p.move(to: P(18.0, 7.0))
            p.addLine(to: P(20.0, 7.0))
            p.move(to: P(4.0, 17.0))
            p.addLine(to: P(6.0, 17.0))
            p.move(to: P(10.0, 17.0))
            p.addLine(to: P(20.0, 17.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 14.0, y: 5.0, width: 4.0, height: 4.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 6.0, y: 15.0, width: 4.0, height: 4.0))
        }
        ]
    case .user:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 8.5, y: 5.0, width: 7.0, height: 7.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(5.0, 20.0))
            p.addCurve(to: P(12.0, 14.5), control1: P(5.6, 16.4), control2: P(8.5, 14.5))
            p.addCurve(to: P(19.0, 20.0), control1: P(15.5, 14.5), control2: P(18.4, 16.4))
        }
        ]
    case .play:
        return [
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.move(to: P(7.0, 4.8))
            p.addLine(to: P(7.0, 19.2))
            p.addCurve(to: P(7.308, 19.705), control1: P(7.007, 19.411), control2: P(7.124, 19.603))
            p.addCurve(to: P(7.9, 19.7), control1: P(7.493, 19.808), control2: P(7.717, 19.806))
            p.addLine(to: P(19.5, 12.5))
            p.addCurve(to: P(19.768, 12.0), control1: P(19.668, 12.389), control2: P(19.768, 12.201))
            p.addCurve(to: P(19.5, 11.5), control1: P(19.768, 11.799), control2: P(19.668, 11.611))
            p.addLine(to: P(7.9, 4.3))
            p.addCurve(to: P(7.308, 4.295), control1: P(7.717, 4.194), control2: P(7.493, 4.192))
            p.addCurve(to: P(7.0, 4.8), control1: P(7.124, 4.397), control2: P(7.007, 4.589))
            p.closeSubpath()
        }
        ]
    case .pause:
        return [
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.addRoundedRect(in: CGRect(x: 6.0, y: 4.5, width: 4.0, height: 15.0), cornerSize: CGSize(width: 1.0, height: 1.0))
        },
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.addRoundedRect(in: CGRect(x: 14.0, y: 4.5, width: 4.0, height: 15.0), cornerSize: CGSize(width: 1.0, height: 1.0))
        }
        ]
    case .next:
        return [
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.move(to: P(6.0, 5.5))
            p.addLine(to: P(6.0, 18.5))
            p.addLine(to: P(15.0, 12.0))
            p.addLine(to: P(6.0, 5.5))
            p.closeSubpath()
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(18.5, 5.0))
            p.addLine(to: P(18.5, 19.0))
        }
        ]
    case .prev:
        return [
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.move(to: P(18.0, 5.5))
            p.addLine(to: P(18.0, 18.5))
            p.addLine(to: P(9.0, 12.0))
            p.addLine(to: P(18.0, 5.5))
            p.closeSubpath()
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(5.5, 5.0))
            p.addLine(to: P(5.5, 19.0))
        }
        ]
    case .shuffle:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(3.0, 7.0))
            p.addLine(to: P(6.5, 7.0))
            p.addCurve(to: P(12.5, 12.0), control1: P(9.5, 7.0), control2: P(11.0, 9.0))
            p.addCurve(to: P(18.5, 17.0), control1: P(14.0, 15.0), control2: P(15.5, 17.0))
            p.addLine(to: P(21.0, 17.0))
            p.move(to: P(3.0, 17.0))
            p.addLine(to: P(6.5, 17.0))
            p.addCurve(to: P(9.9, 15.6), control1: P(7.9, 17.0), control2: P(9.0, 16.5))
            p.move(to: P(14.0, 8.0))
            p.addCurve(to: P(17.5, 7.0), control1: P(15.0, 7.3), control2: P(16.1, 7.0))
            p.addLine(to: P(21.0, 7.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(18.5, 4.5))
            p.addLine(to: P(21.0, 7.0))
            p.addLine(to: P(18.5, 9.5))
            p.move(to: P(18.5, 14.5))
            p.addLine(to: P(21.0, 17.0))
            p.addLine(to: P(18.5, 19.5))
        }
        ]
    case .repeat:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.0, 11.0))
            p.addLine(to: P(4.0, 9.5))
            p.addCurve(to: P(6.5, 7.0), control1: P(4.0, 8.119), control2: P(5.119, 7.0))
            p.addLine(to: P(20.0, 7.0))
            p.move(to: P(20.0, 7.0))
            p.addLine(to: P(17.0, 4.0))
            p.move(to: P(20.0, 7.0))
            p.addLine(to: P(17.0, 10.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(20.0, 13.0))
            p.addLine(to: P(20.0, 14.5))
            p.addCurve(to: P(17.5, 17.0), control1: P(20.0, 15.881), control2: P(18.881, 17.0))
            p.addLine(to: P(4.0, 17.0))
            p.move(to: P(4.0, 17.0))
            p.addLine(to: P(7.0, 14.0))
            p.move(to: P(4.0, 17.0))
            p.addLine(to: P(7.0, 20.0))
        }
        ]
    case .repeatOne:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.0, 11.0))
            p.addLine(to: P(4.0, 9.5))
            p.addCurve(to: P(6.5, 7.0), control1: P(4.0, 8.119), control2: P(5.119, 7.0))
            p.addLine(to: P(20.0, 7.0))
            p.move(to: P(20.0, 7.0))
            p.addLine(to: P(17.0, 4.0))
            p.move(to: P(20.0, 7.0))
            p.addLine(to: P(17.0, 10.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(20.0, 13.0))
            p.addLine(to: P(20.0, 14.5))
            p.addCurve(to: P(17.5, 17.0), control1: P(20.0, 15.881), control2: P(18.881, 17.0))
            p.addLine(to: P(4.0, 17.0))
            p.move(to: P(4.0, 17.0))
            p.addLine(to: P(7.0, 14.0))
            p.move(to: P(4.0, 17.0))
            p.addLine(to: P(7.0, 20.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(11.0, 10.5))
            p.addLine(to: P(12.2, 9.7))
            p.addLine(to: P(12.2, 14.3))
        }
        ]
    case .heart:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 20.0))
            p.addCurve(to: P(4.5, 9.8), control1: P(12.0, 20.0), control2: P(4.5, 15.4))
            p.addCurve(to: P(7.466, 6.151), control1: P(4.677, 8.103), control2: P(5.841, 6.671))
            p.addCurve(to: P(12.0, 7.4), control1: P(9.091, 5.631), control2: P(10.87, 6.121))
            p.addCurve(to: P(16.534, 6.151), control1: P(13.13, 6.121), control2: P(14.909, 5.631))
            p.addCurve(to: P(19.5, 9.8), control1: P(18.159, 6.671), control2: P(19.323, 8.103))
            p.addCurve(to: P(12.0, 20.0), control1: P(19.5, 15.4), control2: P(12.0, 20.0))
            p.closeSubpath()
        }
        ]
    case .heartFill:
        return [
        IconPart(fill: true, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 20.0))
            p.addCurve(to: P(4.5, 9.8), control1: P(12.0, 20.0), control2: P(4.5, 15.4))
            p.addCurve(to: P(7.466, 6.151), control1: P(4.677, 8.103), control2: P(5.841, 6.671))
            p.addCurve(to: P(12.0, 7.4), control1: P(9.091, 5.631), control2: P(10.87, 6.121))
            p.addCurve(to: P(16.534, 6.151), control1: P(13.13, 6.121), control2: P(14.909, 5.631))
            p.addCurve(to: P(19.5, 9.8), control1: P(18.159, 6.671), control2: P(19.323, 8.103))
            p.addCurve(to: P(12.0, 20.0), control1: P(19.5, 15.4), control2: P(12.0, 20.0))
            p.closeSubpath()
        }
        ]
    case .queue:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.0, 6.0))
            p.addLine(to: P(16.0, 6.0))
            p.move(to: P(4.0, 11.0))
            p.addLine(to: P(16.0, 11.0))
            p.move(to: P(4.0, 16.0))
            p.addLine(to: P(11.0, 16.0))
        },
        IconPart(fill: true, stroke: true, cut: false) { p in
            p.move(to: P(17.0, 14.5))
            p.addLine(to: P(17.0, 19.5))
            p.addLine(to: P(21.0, 17.0))
            p.addLine(to: P(17.0, 14.5))
            p.closeSubpath()
        }
        ]
    case .chevronDown:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(6.0, 9.0))
            p.addLine(to: P(12.0, 15.0))
            p.addLine(to: P(18.0, 9.0))
        }
        ]
    case .chevronLeft:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(15.0, 5.0))
            p.addLine(to: P(8.0, 12.0))
            p.addLine(to: P(15.0, 19.0))
        }
        ]
    case .chevronRight:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(9.0, 5.0))
            p.addLine(to: P(16.0, 12.0))
            p.addLine(to: P(9.0, 19.0))
        }
        ]
    case .more:
        return [
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.addEllipse(in: CGRect(x: 4.1, y: 10.6, width: 2.8, height: 2.8))
        },
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.addEllipse(in: CGRect(x: 10.6, y: 10.6, width: 2.8, height: 2.8))
        },
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.addEllipse(in: CGRect(x: 17.1, y: 10.6, width: 2.8, height: 2.8))
        }
        ]
    case .download:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 4.0))
            p.addLine(to: P(12.0, 15.0))
            p.move(to: P(7.5, 10.5))
            p.addLine(to: P(12.0, 15.0))
            p.addLine(to: P(16.5, 10.5))
            p.move(to: P(5.0, 19.5))
            p.addLine(to: P(19.0, 19.5))
        }
        ]
    case .check:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(5.0, 12.5))
            p.addLine(to: P(9.5, 17.0))
            p.addLine(to: P(19.0, 7.5))
        }
        ]
    case .plus:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 5.0))
            p.addLine(to: P(12.0, 19.0))
            p.move(to: P(5.0, 12.0))
            p.addLine(to: P(19.0, 12.0))
        }
        ]
    case .x:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(6.0, 6.0))
            p.addLine(to: P(18.0, 18.0))
            p.move(to: P(18.0, 6.0))
            p.addLine(to: P(6.0, 18.0))
        }
        ]
    case .clock:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 3.5, y: 3.5, width: 17.0, height: 17.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 7.5))
            p.addLine(to: P(12.0, 12.0))
            p.addLine(to: P(15.0, 14.0))
        }
        ]
    case .globe:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 3.5, y: 3.5, width: 17.0, height: 17.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(3.5, 12.0))
            p.addLine(to: P(20.5, 12.0))
            p.move(to: P(12.0, 3.5))
            p.addCurve(to: P(15.8, 12.0), control1: P(14.6, 5.9), control2: P(15.8, 8.8))
            p.addCurve(to: P(12.0, 20.5), control1: P(15.8, 15.2), control2: P(14.6, 18.1))
            p.addCurve(to: P(8.2, 12.0), control1: P(9.4, 18.1), control2: P(8.2, 15.2))
            p.addCurve(to: P(12.0, 3.5), control1: P(8.2, 8.8), control2: P(9.4, 5.9))
            p.closeSubpath()
        }
        ]
    case .file:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(6.5, 3.5))
            p.addLine(to: P(13.5, 3.5))
            p.addLine(to: P(17.5, 7.5))
            p.addLine(to: P(17.5, 20.5))
            p.addLine(to: P(6.5, 20.5))
            p.addLine(to: P(6.5, 3.5))
            p.closeSubpath()
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(13.5, 3.5))
            p.addLine(to: P(13.5, 7.5))
            p.addLine(to: P(17.5, 7.5))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(10.0, 15.5))
            p.addLine(to: P(10.0, 11.5))
            p.addLine(to: P(14.0, 10.7))
            p.addLine(to: P(14.0, 14.7))
        }
        ]
    case .note:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(9.0, 18.0))
            p.addLine(to: P(9.0, 6.0))
            p.addLine(to: P(19.0, 4.0))
            p.addLine(to: P(19.0, 16.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 4.0, y: 15.5, width: 5.0, height: 5.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 14.0, y: 13.5, width: 5.0, height: 5.0))
        }
        ]
    case .up:
        return [
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.move(to: P(12.0, 5.0))
            p.addLine(to: P(6.0, 12.0))
            p.addLine(to: P(18.0, 12.0))
            p.addLine(to: P(12.0, 5.0))
            p.closeSubpath()
        }
        ]
    case .down:
        return [
        IconPart(fill: true, stroke: false, cut: false) { p in
            p.move(to: P(12.0, 19.0))
            p.addLine(to: P(18.0, 12.0))
            p.addLine(to: P(6.0, 12.0))
            p.addLine(to: P(12.0, 19.0))
            p.closeSubpath()
        }
        ]
    case .share:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 15.0))
            p.addLine(to: P(12.0, 4.0))
            p.move(to: P(8.0, 8.0))
            p.addLine(to: P(12.0, 4.0))
            p.addLine(to: P(16.0, 8.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(5.0, 12.0))
            p.addLine(to: P(5.0, 19.5))
            p.addLine(to: P(19.0, 19.5))
            p.addLine(to: P(19.0, 12.0))
        }
        ]
    case .speaker:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.0, 9.5))
            p.addLine(to: P(7.5, 9.5))
            p.addLine(to: P(12.0, 6.0))
            p.addLine(to: P(12.0, 18.0))
            p.addLine(to: P(7.5, 14.5))
            p.addLine(to: P(4.0, 14.5))
            p.addLine(to: P(4.0, 9.5))
            p.closeSubpath()
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(15.5, 9.0))
            p.addCurve(to: P(16.854, 12.0), control1: P(16.361, 9.759), control2: P(16.854, 10.852))
            p.addCurve(to: P(15.5, 15.0), control1: P(16.854, 13.148), control2: P(16.361, 14.241))
            p.move(to: P(18.0, 6.5))
            p.addCurve(to: P(20.401, 12.0), control1: P(19.531, 7.919), control2: P(20.401, 9.912))
            p.addCurve(to: P(18.0, 17.5), control1: P(20.401, 14.088), control2: P(19.531, 16.081))
        }
        ]
    case .speakerMute:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.0, 9.5))
            p.addLine(to: P(7.5, 9.5))
            p.addLine(to: P(12.0, 6.0))
            p.addLine(to: P(12.0, 18.0))
            p.addLine(to: P(7.5, 14.5))
            p.addLine(to: P(4.0, 14.5))
            p.addLine(to: P(4.0, 9.5))
            p.closeSubpath()
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(16.0, 9.5))
            p.addLine(to: P(21.0, 14.5))
            p.move(to: P(21.0, 9.5))
            p.addLine(to: P(16.0, 14.5))
        }
        ]
    case .moon:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(19.5, 14.5))
            p.addCurve(to: P(11.489, 12.511), control1: P(16.667, 15.372), control2: P(13.585, 14.607))
            p.addCurve(to: P(9.5, 4.5), control1: P(9.393, 10.415), control2: P(8.628, 7.333))
            p.addCurve(to: P(3.894, 12.941), control1: P(5.86, 5.621), control2: P(3.515, 9.152))
            p.addCurve(to: P(11.059, 20.106), control1: P(4.272, 16.73), control2: P(7.27, 19.728))
            p.addCurve(to: P(19.5, 14.5), control1: P(14.848, 20.485), control2: P(18.379, 18.14))
            p.closeSubpath()
        }
        ]
    case .sun:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 8.0, y: 8.0, width: 8.0, height: 8.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 3.0))
            p.addLine(to: P(12.0, 5.0))
            p.move(to: P(12.0, 19.0))
            p.addLine(to: P(12.0, 21.0))
            p.move(to: P(3.0, 12.0))
            p.addLine(to: P(5.0, 12.0))
            p.move(to: P(19.0, 12.0))
            p.addLine(to: P(21.0, 12.0))
            p.move(to: P(5.6, 5.6))
            p.addLine(to: P(7.0, 7.0))
            p.move(to: P(17.0, 17.0))
            p.addLine(to: P(18.4, 18.4))
            p.move(to: P(18.4, 5.6))
            p.addLine(to: P(17.0, 7.0))
            p.move(to: P(7.0, 17.0))
            p.addLine(to: P(5.6, 18.4))
        }
        ]
    case .storage:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 4.5, y: 3.7, width: 15.0, height: 5.6))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.5, 6.5))
            p.addLine(to: P(4.5, 17.5))
            p.addCurve(to: P(12.0, 20.3), control1: P(4.5, 19.0), control2: P(7.9, 20.3))
            p.addCurve(to: P(19.5, 17.5), control1: P(16.1, 20.3), control2: P(19.5, 19.0))
            p.addLine(to: P(19.5, 6.5))
            p.move(to: P(4.5, 12.0))
            p.addCurve(to: P(12.0, 14.8), control1: P(4.5, 13.5), control2: P(7.9, 14.8))
            p.addCurve(to: P(19.5, 12.0), control1: P(16.1, 14.8), control2: P(19.5, 13.5))
        }
        ]
    case .plug:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(9.0, 3.5))
            p.addLine(to: P(9.0, 8.5))
            p.move(to: P(15.0, 3.5))
            p.addLine(to: P(15.0, 8.5))
            p.move(to: P(6.5, 8.5))
            p.addLine(to: P(17.5, 8.5))
            p.addLine(to: P(17.5, 11.5))
            p.addCurve(to: P(12.0, 17.0), control1: P(17.5, 14.538), control2: P(15.038, 17.0))
            p.addCurve(to: P(6.5, 11.5), control1: P(8.962, 17.0), control2: P(6.5, 14.538))
            p.addLine(to: P(6.5, 8.5))
            p.closeSubpath()
            p.move(to: P(12.0, 17.0))
            p.addLine(to: P(12.0, 20.5))
        }
        ]
    case .lock:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addRoundedRect(in: CGRect(x: 5.0, y: 10.5, width: 14.0, height: 9.5), cornerSize: CGSize(width: 1.5, height: 1.5))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(8.0, 10.5))
            p.addLine(to: P(8.0, 8.0))
            p.addCurve(to: P(12.0, 4.0), control1: P(8.0, 5.791), control2: P(9.791, 4.0))
            p.addCurve(to: P(16.0, 8.0), control1: P(14.209, 4.0), control2: P(16.0, 5.791))
            p.addLine(to: P(16.0, 10.5))
        }
        ]
    case .info:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.addEllipse(in: CGRect(x: 3.5, y: 3.5, width: 17.0, height: 17.0))
        },
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 11.0))
            p.addLine(to: P(12.0, 16.5))
            p.move(to: P(12.0, 7.8))
            p.addLine(to: P(12.0, 7.9))
        }
        ]
    case .list:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.0, 7.0))
            p.addLine(to: P(20.0, 7.0))
            p.move(to: P(4.0, 12.0))
            p.addLine(to: P(20.0, 12.0))
            p.move(to: P(4.0, 17.0))
            p.addLine(to: P(14.0, 17.0))
        }
        ]
    case .fullscreen:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(4.0, 9.0))
            p.addLine(to: P(4.0, 4.0))
            p.addLine(to: P(9.0, 4.0))
            p.move(to: P(20.0, 9.0))
            p.addLine(to: P(20.0, 4.0))
            p.addLine(to: P(15.0, 4.0))
            p.move(to: P(4.0, 15.0))
            p.addLine(to: P(4.0, 20.0))
            p.addLine(to: P(9.0, 20.0))
            p.move(to: P(20.0, 15.0))
            p.addLine(to: P(20.0, 20.0))
            p.addLine(to: P(15.0, 20.0))
        }
        ]
    case .sparkle:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(12.0, 3.5))
            p.addLine(to: P(14.0, 10.0))
            p.addLine(to: P(20.5, 12.0))
            p.addLine(to: P(14.0, 14.0))
            p.addLine(to: P(12.0, 20.5))
            p.addLine(to: P(10.0, 14.0))
            p.addLine(to: P(3.5, 12.0))
            p.addLine(to: P(10.0, 10.0))
            p.addLine(to: P(12.0, 3.5))
            p.closeSubpath()
        }
        ]
    case .trash:
        return [
        IconPart(fill: false, stroke: true, cut: false) { p in
            p.move(to: P(5.0, 7.0))
            p.addLine(to: P(19.0, 7.0))
            p.move(to: P(10.0, 7.0))
            p.addLine(to: P(10.0, 4.5))
            p.addLine(to: P(14.0, 4.5))
            p.addLine(to: P(14.0, 7.0))
            p.move(to: P(7.0, 7.0))
            p.addLine(to: P(7.8, 19.5))
            p.addLine(to: P(16.2, 19.5))
            p.addLine(to: P(17.0, 7.0))
        }
        ]
        }
    }
}

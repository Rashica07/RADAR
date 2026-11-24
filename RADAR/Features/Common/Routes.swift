import SwiftUI

/// Where a push can go. Every tab's `NavigationStack` resolves these the same way.
enum Route: Hashable {
    case artist(String)
    case album(String)
    case playlist(String)
    case userPlaylist(String)
    case genre(String)
}

extension View {
    /// Registers the shared destinations and the Settings button on a tab root.
    func radarDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .artist(let id): ArtistScreen(id: id)
            case .album(let id): TrackCollectionScreen(source: .album(id))
            case .playlist(let id): TrackCollectionScreen(source: .editorial(id))
            case .userPlaylist(let id): TrackCollectionScreen(source: .user(id))
            case .genre(let id): TrackCollectionScreen(source: .genre(id))
            }
        }
    }
}

/// Brand background behind a native list or form.
extension View {
    func radarListBackground() -> some View {
        scrollContentBackground(.hidden).background(Color.radarBg)
    }
}

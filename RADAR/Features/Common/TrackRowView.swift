import SwiftUI

/// A track in a native `List`: cover, title, artist and a trailing status. Tap plays; swipe saves
/// or queues; the context menu has the rest. Uses system buttons, menus and swipe actions.
struct TrackRowView: View {
    let track: Track
    /// The list this row belongs to, so Next/Previous stay inside it.
    let context: [String]
    var rank: Int?
    var delta: Int?

    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library
    @Environment(ToastCenter.self) private var toasts

    var body: some View {
        let catalog = DemoCatalog.shared
        let isCurrent = player.current?.id == track.id
        Button {
            player.play(track.id, in: context)
        } label: {
            HStack(spacing: 12) {
                if let rank {
                    Text("\(rank)")
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .frame(width: 28)
                        .foregroundStyle(rank == 1 ? Color.radarAccentText : .primary)
                }
                ArtworkView(catalog.art(for: track))
                    .frame(width: 48, height: 48)
                    .clipShape(.rect(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.body.weight(.medium)).lineLimit(1)
                        .foregroundStyle(isCurrent ? Color.radarAccentText : .primary)
                    HStack(spacing: 4) {
                        if track.explicit { Image(systemName: "e.square.fill").imageScale(.small) }
                        Text(catalog.artistName(for: track)).lineLimit(1)
                    }
                    .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if isCurrent {
                    Image(systemName: player.isPlaying ? "waveform" : "pause.fill")
                        .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                        .foregroundStyle(Color.radarAccentText)
                } else if let delta {
                    Movement(delta: delta, isNew: track.isNew && rank != nil && delta == 0)
                }
                if library.isSaved(track.id) {
                    Image(systemName: "heart.fill").foregroundStyle(Color.radarSignalText).imageScale(.small)
                        .accessibilityLabel("Saved")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button { player.playNext(track.id); toasts.show("Plays next", symbol: "text.insert") } label: {
                Label("Play next", systemImage: "text.insert")
            }.tint(.indigo)
        }
        .swipeActions(edge: .trailing) {
            Button { toggleSave() } label: {
                Label(library.isSaved(track.id) ? "Unsave" : "Save", systemImage: library.isSaved(track.id) ? "heart.slash" : "heart")
            }.tint(Color.radarSignal)
        }
        .contextMenu { TrackMenu(track: track) } preview: {
            ArtworkView(catalog.art(for: track)).frame(width: 240, height: 240)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Plays this track")
    }

    private func toggleSave() {
        let saved = library.toggleSave(track.id)
        toasts.show(saved ? "Saved to Library" : "Removed from Library", symbol: saved ? "heart.fill" : "heart.slash")
    }
}

private extension TrackRowView {
    var catalog: DemoCatalog { .shared }
}

/// The long-press menu, shared with the player.
struct TrackMenu: View {
    let track: Track
    @Environment(PlayerStore.self) private var player
    @Environment(LibraryStore.self) private var library
    @Environment(ToastCenter.self) private var toasts

    var body: some View {
        Button { player.playNext(track.id); toasts.show("Plays next", symbol: "text.insert") } label: {
            Label("Play next", systemImage: "text.insert")
        }
        Button { player.enqueue(track.id); toasts.show("Added to queue", symbol: "text.append") } label: {
            Label("Add to queue", systemImage: "text.append")
        }
        Button {
            let saved = library.toggleSave(track.id)
            toasts.show(saved ? "Saved to Library" : "Removed from Library", symbol: saved ? "heart.fill" : "heart.slash")
        } label: {
            Label(library.isSaved(track.id) ? "Remove from Saved" : "Save", systemImage: library.isSaved(track.id) ? "heart.slash" : "heart")
        }
        Menu {
            ForEach(library.playlists) { list in
                Button(list.title) {
                    let added = library.add(track.id, to: list.id)
                    toasts.show(added ? "Added to \(list.title)" : "Already in \(list.title)", symbol: added ? "checkmark" : "info.circle")
                }
            }
            Button {
                let list = library.createPlaylist()
                _ = library.add(track.id, to: list.id)
                toasts.show("Added to \(list.title)", symbol: "checkmark")
            } label: { Label("New playlist", systemImage: "plus") }
        } label: { Label("Add to playlist", systemImage: "music.note.list") }
        ShareLink(item: "\(track.title) · \(DemoCatalog.shared.artistName(for: track))")
    }
}

/// Chart movement: arrow and places, or "New".
struct Movement: View {
    let delta: Int
    var isNew = false

    var body: some View {
        if isNew {
            Text("NEW").font(.caption2.weight(.bold)).padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.radarSignal, in: .capsule).foregroundStyle(Color.radarOnSignal)
        } else if delta != 0 {
            Label("\(abs(delta))", systemImage: delta > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(delta > 0 ? Color.radarSignalText : .secondary)
                .accessibilityLabel(delta > 0 ? "Up \(delta)" : "Down \(abs(delta))")
        }
    }
}

/// A square cover with a title under it, for horizontal rails.
struct CoverTile: View {
    let art: ArtSpec
    let title: String
    var subtitle: String?
    var width: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ArtworkView(art).frame(width: width, height: width).clipShape(.rect(cornerRadius: 8))
            Text(title).font(.subheadline.weight(.semibold)).lineLimit(1)
            if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
        }
        .frame(width: width, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

import SwiftUI
import Foundation
import TuckiiCore

struct FocusModeView: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let collectionID: UUID?

    @State private var deck: [UUID] = []
    @State private var index = 0
    @State private var dragOffset: CGFloat = 0

    private var stageInk: Color { Color(hex: 0xF5F5F2) }

    private var currentID: UUID? {
        guard index >= 0, index < deck.count else { return nil }
        return deck[index]
    }

    private var scopeTitle: String {
        if let collectionID, let collection = store.collection(collectionID) {
            return collection.name.uppercased()
        }
        return "NEW SAVES"
    }

    var body: some View {
        ZStack {
            Color(hex: 0x0C0C0E).ignoresSafeArea()
            VStack(spacing: 10) {
                header
                if deck.isEmpty {
                    emptyState
                } else {
                    deckArea
                        .frame(maxHeight: .infinity)
                    footer
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .onAppear(perform: buildDeck)
        .onChange(of: index) { _ in
            markCurrentSeen()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(scopeTitle)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(stageInk.opacity(0.5))
                    Text("\(String(format: "%02d", min(index + 1, max(deck.count, 1)))) / \(String(format: "%02d", deck.count))")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(stageInk)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(stageInk.opacity(0.85))
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 6) {
                ForEach(deck.indices, id: \.self) { barIndex in
                    Capsule()
                        .fill(barIndex <= index ? Theme.highlighter : Color.white.opacity(0.16))
                        .frame(height: 5)
                }
            }
        }
    }

    private var deckArea: some View {
        ZStack {
            ForEach(visibleIndices, id: \.self) { deckIndex in
                if let bookmark = store.bookmark(deck[deckIndex]) {
                    card(bookmark, depth: deckIndex - index)
                        .scaleEffect(1 - CGFloat(max(0, deckIndex - index)) * 0.045)
                        .offset(y: CGFloat(max(0, deckIndex - index)) * 14)
                        .offset(x: deckIndex == index ? dragOffset : 0)
                        .rotationEffect(.degrees(deckIndex == index ? Double(dragOffset) / 28 : 0))
                        .zIndex(Double(deck.count - deckIndex))
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    if value.translation.width < -110 {
                        advance(by: 1)
                    } else if value.translation.width > 110 {
                        advance(by: -1)
                    }
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        dragOffset = 0
                    }
                }
        )
    }

    private var visibleIndices: [Int] {
        Array(index..<min(index + 3, deck.count))
    }

    private func card(_ bookmark: Bookmark, depth: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(bookmark.displayInitial)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.gray.opacity(0.2)))
                Text(bookmark.sourceLabel)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ZStack(alignment: .bottomLeading) {
                ZStack {
                    PlaceholderStyle.color(for: bookmark.placeholderSeed)
                    Text(bookmark.displayInitial)
                        .font(.system(size: 64, weight: .black))
                        .foregroundStyle(Theme.ink.opacity(0.8))
                    if let imageURL = bookmark.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2))

                if let collection = store.collection(bookmark.collectionID) {
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: collection.colorHex))
                            .frame(width: 10, height: 10)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.ink, lineWidth: 1))
                        Text(collection.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.ink, lineWidth: 1.5))
                    .padding(8)
                }
            }
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 8) {
                Text(bookmark.title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                if let summary = bookmark.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                let bookmarkTags = store.tags(for: bookmark.id)
                if !bookmarkTags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(bookmarkTags) { tag in
                            Text("#\(tag.name)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Theme.chipGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.ink, lineWidth: 1.5))
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.card)
        )
        .shadow(color: .black.opacity(depth == 0 ? 0.35 : 0.15), radius: depth == 0 ? 18 : 6, y: depth == 0 ? 10 : 3)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            footerCircleButton(systemName: "arrow.left", disabled: index == 0) {
                advance(by: -1)
            }
            openLinkButton
            footerCircleButton(systemName: "arrow.right", disabled: index >= deck.count - 1) {
                advance(by: 1)
            }
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private var openLinkButton: some View {
        let bookmark = currentID.flatMap { store.bookmark($0) }
        if let bookmark, let url = bookmark.url {
            Link(destination: url) {
                HStack(spacing: 6) {
                    Text("Open link")
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: 0x111111))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.ctaYellow))
            }
            .buttonStyle(.plain)
        } else {
            Text("No link")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(stageInk.opacity(0.4))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.1)))
        }
    }

    private func footerCircleButton(systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(disabled ? stageInk.opacity(0.25) : stageInk)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(stageInk.opacity(0.7))
            Text("You're all caught up")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(stageInk)
            Text("New saves will show up here.")
                .font(.system(size: 14))
                .foregroundStyle(stageInk.opacity(0.6))
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: 0x111111))
                    .padding(.horizontal, 28)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ctaYellow))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func buildDeck() {
        if let collectionID {
            deck = store.sortedBookmarks(in: collectionID).map(\.id)
        } else {
            deck = store.bookmarks
                .filter { !$0.isSeen }
                .sorted { $0.createdAt > $1.createdAt }
                .map(\.id)
        }
        index = 0
        markCurrentSeen()
    }

    private func markCurrentSeen() {
        if let currentID {
            store.markSeen(currentID)
        }
    }

    private func advance(by delta: Int) {
        let newIndex = min(max(index + delta, 0), max(deck.count - 1, 0))
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            index = newIndex
        }
    }
}

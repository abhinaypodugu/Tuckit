import SwiftUI
import Foundation
import TuckiiCore

public struct SearchView: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""

    public init() {}

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [Bookmark] {
        store.search(trimmedQuery)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 14) {
                    searchBar
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            if trimmedQuery.isEmpty {
                                libraryStatsCard
                                recentlySavedSection
                                typeToSearchPrompt
                            } else {
                                resultsSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationDestination(for: Bookmark.self) { bookmark in
                LinkDetailView(bookmarkID: bookmark.id)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                TextField("Find collections or save...", text: $query)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .foregroundStyle(Theme.ink)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Text("Clear")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.card))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 1.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var libraryStatsCard: some View {
        let statInk = Color(hex: 0x111111)
        return VStack(alignment: .leading, spacing: 14) {
            Text("YOUR LIBRARY")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(statInk.opacity(0.9))
            HStack(spacing: 0) {
                statItem("folder", value: store.stats.collections, label: "Collections", ink: statInk)
                statDivider
                statItem("bookmark", value: store.stats.saves, label: "Saves", ink: statInk)
                statDivider
                statItem("pin", value: store.stats.pinned, label: "Pinned", ink: statInk)
                statDivider
                statItem("tag", value: store.stats.tags, label: "Tags", ink: statInk)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.highlighter))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.ink, lineWidth: 2.5))
    }

    private func statItem(_ icon: String, value: Int, label: String, ink: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(ink)
            Text("\(value)")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(ink)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ink.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color(hex: 0x111111).opacity(0.25))
            .frame(width: 1, height: 52)
    }

    private var recentlySavedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("RECENTLY SAVED")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.ink)
            }
            if store.bookmarks.isEmpty {
                Text("Nothing saved yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                    spacing: 16
                ) {
                    ForEach(store.recentlySaved(limit: 6)) { bookmark in
                        NavigationLink(value: bookmark) {
                            BookmarkCard(
                                bookmark: bookmark,
                                collectionChip: chip(for: bookmark),
                                tags: store.tags(for: bookmark.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func chip(for bookmark: Bookmark) -> (name: String, colorHex: UInt32)? {
        guard let collection = store.collection(bookmark.collectionID) else { return nil }
        return (collection.name, collection.colorHex)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SAVES (\(results.count))")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Theme.ink.opacity(0.6))
            if results.isEmpty {
                Text("No saves match \"\(trimmedQuery)\".")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                    spacing: 16
                ) {
                    ForEach(results) { bookmark in
                        NavigationLink(value: bookmark) {
                            BookmarkCard(
                                bookmark: bookmark,
                                collectionChip: chip(for: bookmark),
                                tags: store.tags(for: bookmark.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var typeToSearchPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.ink.opacity(0.7))
            Text("Type something to search...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.ink.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 36)
    }
}

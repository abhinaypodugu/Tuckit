import SwiftUI
import TuckiiCore

struct CollectionScreen: View {
    @EnvironmentObject private var store: LibraryStore
    let collectionID: UUID

    @State private var showFocus = false

    private var collection: TuckiiCollection? { store.collection(collectionID) }
    private var pinned: [Bookmark] { store.pinnedBookmarks(in: collectionID) }
    private var saves: [Bookmark] { store.unpinnedBookmarks(in: collectionID) }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            if let collection {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(collection.name)
                                    .font(.system(size: 30, weight: .black, design: .rounded))
                                    .foregroundStyle(Theme.ink)
                                Text("\(pinned.count + saves.count) \(pinned.count + saves.count == 1 ? "item" : "items") · \(store.subcollections(of: collectionID).count) subcollections")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                showFocus = true
                            } label: {
                                Image(systemName: "square.stack.3d.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 42, height: 42)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ctaYellow))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
                            }
                            .buttonStyle(.plain)
                            Menu {
                                ForEach(SaveSort.allCases, id: \.self) { sort in
                                    Button(sort.displayName) {
                                        store.setSaveSort(sort, for: collectionID)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 42, height: 42)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.ctaYellow))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
                            }
                        }

                        if pinned.isEmpty && saves.isEmpty {
                            emptyState
                        } else {
                            if !pinned.isEmpty {
                                section("PINNED (\(pinned.count))", bookmarks: pinned)
                            }
                            section("SAVES (\(saves.count))", bookmarks: saves)
                        }
                        Spacer(minLength: 24)
                    }
                    .padding(20)
                }
            } else {
                Text("Collection not found")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Bookmark.self) { bookmark in
            LinkDetailView(bookmarkID: bookmark.id)
        }
        .fullScreenCover(isPresented: $showFocus) {
            FocusModeView(collectionID: collectionID)
                .environmentObject(store)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 52))
                .foregroundStyle(.gray.opacity(0.45))
                .padding(.bottom, 6)
            Text("No saves yet")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("Use quick save on the home screen or share a link to get started.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private func section(_ title: String, bookmarks: [Bookmark]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Theme.ink.opacity(0.55))
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 16
            ) {
                ForEach(bookmarks) { bookmark in
                    NavigationLink(value: bookmark) {
                        BookmarkCard(bookmark: bookmark)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

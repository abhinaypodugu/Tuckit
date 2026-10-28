import SwiftUI
import Foundation
import TuckiiCore

struct CollectionScreen: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let collectionID: UUID

    @State private var showFocus = false
    @State private var showProUpsell = false
    @State private var proFeature: ProFeature = .subCollections
    @State private var selecting = false
    @State private var selection: Set<UUID> = []
    @State private var showSortSheet = false
    @State private var showAddLinkAlert = false
    @State private var addLinkText = ""
    @State private var showDeleteCollectionConfirm = false
    @State private var showDeleteSelectedConfirm = false
    @State private var showBulkMoveSheet = false
    @State private var alertInfo: CollectionAlert?

    private var collection: TuckiiCollection? { store.collection(collectionID) }
    private var pinned: [Bookmark] { store.pinnedBookmarks(in: collectionID) }
    private var saves: [Bookmark] { store.unpinnedBookmarks(in: collectionID) }
    private var allBookmarks: [Bookmark] { pinned + saves }

    private var selectedURLs: [URL] {
        allBookmarks.filter { selection.contains($0.id) }.compactMap(\.url)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let collection {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if selecting {
                            selectToolbar
                        } else {
                            header(collection)
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
        .inlineNavigationTitle
        .navigationDestination(for: Bookmark.self) { bookmark in
            LinkDetailView(bookmarkID: bookmark.id)
        }
        .fullScreenPresentation(isPresented: $showFocus) {
            FocusModeView(collectionID: collectionID)
                .environmentObject(store)
        }
        .sheet(isPresented: $showProUpsell) {
            ProUpsellSheet(feature: proFeature)
                .environmentObject(store)
        }
        .sheet(isPresented: $showBulkMoveSheet) {
            MoveSheet(bookmarkIDs: Array(selection)) {
                selecting = false
                selection.removeAll()
            }
            .environmentObject(store)
        }
        .confirmationDialog("Sort saves", isPresented: $showSortSheet, titleVisibility: .visible) {
            if let collection {
                ForEach(SaveSort.allCases, id: \.self) { sort in
                    Button(sort.displayName) {
                        store.setSaveSort(sort, for: collection.id)
                    }
                }
            }
        }
        .confirmationDialog("Delete link", isPresented: $showDeleteSelectedConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteBookmarks(selection)
                selection.removeAll()
                selecting = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Permanently delete the selected links?")
        }
        .alert("Add Link", isPresented: $showAddLinkAlert) {
            TextField("https://", text: $addLinkText)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
            Button("Add") {
                addLink()
            }
            Button("Cancel", role: .cancel) {
                addLinkText = ""
            }
        } message: {
            Text("Paste a link to save it in this collection.")
        }
        .alert("Delete collection", isPresented: $showDeleteCollectionConfirm) {
            Button("Delete", role: .destructive) {
                try? store.deleteCollection(collectionID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Saves inside will be moved to Unsorted.")
        }
        .alert(item: $alertInfo) { info in
            Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
        }
    }

    private func header(_ collection: TuckiiCollection) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("\(allBookmarks.count) \(allBookmarks.count == 1 ? "item" : "items") · \(store.subcollections(of: collectionID).count) subcollections")
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
                Button {
                    addLinkText = ""
                    showAddLinkAlert = true
                } label: {
                    Label("Add Link", systemImage: "plus")
                }
                Button {
                    selecting = true
                } label: {
                    Label("Select Links", systemImage: "checkmark.square")
                }
                Button {
                    proFeature = .subCollections
                    showProUpsell = true
                } label: {
                    Label("Create Sub-collection", systemImage: "folder.badge.plus")
                }
                Button {
                    proFeature = .shareCollection
                    showProUpsell = true
                } label: {
                    Label("Share Collection", systemImage: "square.and.arrow.up")
                }
                Button {
                    showSortSheet = true
                } label: {
                    Label("Sort saves", systemImage: "arrow.up.arrow.down")
                }
                Divider()
                Button(role: .destructive) {
                    showDeleteCollectionConfirm = true
                } label: {
                    Label("Delete Collection", systemImage: "trash")
                }
                .disabled(collection.isSystem)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 42, height: 42)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink, lineWidth: 2.5))
            }
        }
    }

    private var selectToolbar: some View {
        HStack(spacing: 8) {
            Text("\(selection.count) selected")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Spacer(minLength: 0)
            Button("All") {
                selection = Set(allBookmarks.map(\.id))
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 1.8))

            if selectedURLs.isEmpty {
                selectActionLabel("Share", enabled: false)
            } else {
                ShareLink(
                    items: selectedURLs,
                    preview: SharePreview("Tuckii links", image: Image(systemName: "link"))
                ) {
                    selectActionLabel("Share", enabled: true)
                }
            }
            Button {
                showBulkMoveSheet = true
            } label: {
                selectActionLabel("Move", enabled: !selection.isEmpty)
            }
            .buttonStyle(.plain)
            .disabled(selection.isEmpty)
            Button {
                showDeleteSelectedConfirm = true
            } label: {
                selectActionLabel("Delete", enabled: !selection.isEmpty, tint: Theme.danger)
            }
            .buttonStyle(.plain)
            .disabled(selection.isEmpty)
            Button("Cancel") {
                selecting = false
                selection.removeAll()
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 1.8))
        }
        .padding(.top, 4)
    }

    private func selectActionLabel(_ text: String, enabled: Bool, tint: Color = Theme.ink) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(enabled ? tint : tint.opacity(0.35))
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink.opacity(enabled ? 1 : 0.3), lineWidth: 1.8))
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
            Text("Use quick save on the home screen or add a link from the menu.")
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
                    if selecting {
                        Button {
                            toggleSelection(bookmark.id)
                        } label: {
                            BookmarkCard(bookmark: bookmark)
                                .overlay(alignment: .topLeading) {
                                    selectionMark(isSelected: selection.contains(bookmark.id))
                                }
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: bookmark) {
                            BookmarkCard(bookmark: bookmark)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func selectionMark(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Theme.ink : Theme.card)
                .frame(width: 24, height: 24)
            Circle()
                .stroke(Theme.ink, lineWidth: 2)
                .frame(width: 24, height: 24)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Theme.card)
            }
        }
        .padding(8)
    }

    private func toggleSelection(_ id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }

    private func addLink() {
        guard let url = URLNormalizer.normalize(addLinkText) else {
            alertInfo = CollectionAlert(title: "No URL", message: "Please enter a link to save")
            return
        }
        do {
            let bookmark = try store.addBookmark(url: url, to: collectionID)
            addLinkText = ""
            Task {
                await store.refreshMetadata(for: bookmark.id)
            }
        } catch let error as LibraryError {
            alertInfo = CollectionAlert(title: error.title, message: error.message)
        } catch {
            alertInfo = CollectionAlert(title: "Couldn't save", message: error.localizedDescription)
        }
    }
}

private struct CollectionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

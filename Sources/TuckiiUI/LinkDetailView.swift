import SwiftUI
import Foundation
import TuckiiCore

public struct LinkDetailView: View {
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let bookmarkID: UUID

    public init(bookmarkID: UUID) {
        self.bookmarkID = bookmarkID
    }

    @State private var editingTitle = false
    @State private var titleDraft = ""
    @State private var editingNotes = false
    @State private var notesDraft = ""
    @State private var showMove = false
    @State private var showDeleteConfirm = false
    @State private var showProUpsell = false
    @State private var showTagEditor = false
    @State private var isRefreshing = false

    private var bookmark: Bookmark? { store.bookmark(bookmarkID) }

    public var body: some View {
        ZStack(alignment: .top) {
            Theme.cream.ignoresSafeArea()
            if let bookmark {
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .top) {
                        hero(for: bookmark)
                        detailsCard(for: bookmark)
                            .padding(.horizontal, 18)
                            .padding(.top, 322)
                    }
                    .padding(.bottom, 32)
                }
                controls(for: bookmark)
            } else {
                Text("Save not found")
                    .foregroundStyle(.secondary)
            }
        }
        .hiddenNavigationChrome
        .sheet(isPresented: $showMove) {
            MoveSheet(bookmarkID: bookmarkID)
                .environmentObject(store)
        }
        .sheet(isPresented: $showProUpsell) {
            ProUpsellSheet(feature: .tags)
                .environmentObject(store)
        }
        .sheet(isPresented: $showTagEditor) {
            TagEditorSheet(bookmarkID: bookmarkID)
                .environmentObject(store)
        }
        .confirmationDialog("Delete link", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteBookmark(bookmarkID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Permanently delete this link?")
        }
        .onAppear {
            store.markSeen(bookmarkID)
        }
        .task {
            await loadMetadata(force: false)
        }
    }

    private func hero(for bookmark: Bookmark) -> some View {
        ZStack {
            PlaceholderStyle.color(for: bookmark.placeholderSeed)
            Text(bookmark.displayInitial)
                .font(.system(size: 96, weight: .black))
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
        .frame(height: 382)
        .clipped()
    }

    private func controls(for bookmark: Bookmark) -> some View {
        HStack {
            roundControl(systemName: "arrow.left") {
                dismiss()
            }
            Spacer()
            roundControl(systemName: bookmark.isPinned ? "pin.fill" : "pin", active: bookmark.isPinned) {
                store.togglePin(bookmarkID)
                Haptics.tap(store.settings.hapticsEnabled)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private func roundControl(systemName: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(active ? Theme.ctaYellow : Theme.card.opacity(0.94))
                )
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.ink, lineWidth: 2.5))
        }
        .buttonStyle(.plain)
    }

    private func detailsCard(for bookmark: Bookmark) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sourceRow(bookmark)
            titleRow(bookmark)
            metaRow(bookmark)
            if bookmark.url != nil {
                openLinkButton(bookmark)
            }
            actionsRow(bookmark)
            tagsSection(bookmark)
            notesSection(bookmark)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.ink, lineWidth: 2.5))
        )
    }

    private func sourceRow(_ bookmark: Bookmark) -> some View {
        HStack(spacing: 8) {
            Text(bookmark.displayInitial)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.gray.opacity(0.2)))
            Text(bookmark.sourceLabel)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Theme.ink)
        }
    }

    private func titleRow(_ bookmark: Bookmark) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if editingTitle {
                TextField("Title", text: $titleDraft)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ctaYellow, lineWidth: 2.5))
                HStack {
                    Spacer()
                    smallOutlineButton("Cancel") {
                        editingTitle = false
                    }
                    smallYellowButton("Save") {
                        store.updateTitle(titleDraft, for: bookmarkID)
                        editingTitle = false
                    }
                }
            } else {
                HStack(alignment: .top) {
                    Text(bookmark.title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 8)
                    Button {
                        titleDraft = bookmark.title
                        editingTitle = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 38, height: 38)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func metaRow(_ bookmark: Bookmark) -> some View {
        HStack(spacing: 10) {
            if let collection = store.collection(bookmark.collectionID) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: collection.colorHex))
                        .frame(width: 12, height: 12)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.ink, lineWidth: 1.5))
                    Text(collection.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 1.8))
            }
            Text(Self.dateText(bookmark.createdAt))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func openLinkButton(_ bookmark: Bookmark) -> some View {
        Link(destination: bookmark.url ?? URL(string: "https://example.com")!) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open link")
                        .font(.system(size: 18, weight: .heavy))
                    Text(bookmark.displayDomain)
                        .font(.system(size: 13, weight: .medium))
                        .opacity(0.75)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.ink))
            }
            .foregroundStyle(Theme.ink)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.ctaYellow))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
        }
        .buttonStyle(.plain)
    }

    private func actionsRow(_ bookmark: Bookmark) -> some View {
        HStack(spacing: 0) {
            if let url = bookmark.url {
                ShareLink(item: url) {
                    actionLabel("Share", systemName: "square.and.arrow.up")
                }
            } else {
                actionLabel("Share", systemName: "square.and.arrow.up", enabled: false)
            }
            actionDivider
            Button {
                showMove = true
            } label: {
                actionLabel("Move", systemName: "folder")
            }
            .buttonStyle(.plain)
            actionDivider
            Button {
                Task { await loadMetadata(force: true) }
            } label: {
                actionLabel(isRefreshing ? "Refreshing" : "Refresh", systemName: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.plain)
            actionDivider
            Button {
                showDeleteConfirm = true
            } label: {
                actionLabel("Delete", systemName: "trash", tint: Theme.danger)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink, lineWidth: 2.5))
    }

    private var actionDivider: some View {
        Rectangle()
            .fill(Theme.ink.opacity(0.25))
            .frame(width: 1, height: 42)
    }

    private func actionLabel(_ text: String, systemName: String, tint: Color = Theme.ink, enabled: Bool = true) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(enabled ? tint : tint.opacity(0.35))
        .frame(maxWidth: .infinity)
    }

    private func tagsSection(_ bookmark: Bookmark) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TAGS")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Theme.ink.opacity(0.6))
            HStack(spacing: 8) {
                ForEach(store.tags(for: bookmarkID)) { tag in
                    Text("#\(tag.name)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 7).fill(Theme.chipGreen))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.ink, lineWidth: 1.5))
                }
                Button {
                    if store.isPro {
                        showTagEditor = true
                    } else {
                        showProUpsell = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.highlighter)
                        Text("Add")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.ink, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
    }

    private func notesSection(_ bookmark: Bookmark) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NOTES")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                Spacer()
                if editingNotes {
                    smallOutlineButton("Cancel") {
                        editingNotes = false
                        notesDraft = bookmark.notes ?? ""
                    }
                    smallYellowButton("Update") {
                        store.updateNotes(notesDraft, for: bookmarkID)
                        editingNotes = false
                    }
                }
            }
            if editingNotes {
                TextEditor(text: $notesDraft)
                    .frame(minHeight: 96)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.fieldWarm))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink.opacity(0.4), lineWidth: 2))
                    .foregroundStyle(Theme.ink)
            } else {
                Button {
                    notesDraft = bookmark.notes ?? ""
                    editingNotes = true
                } label: {
                    Text(bookmark.notes ?? "Tap to add notes...")
                        .font(.system(size: 15))
                        .foregroundStyle(bookmark.notes == nil ? Color.secondary : Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.fieldWarm))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.ink.opacity(0.35), lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func smallOutlineButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(RoundedRectangle(cornerRadius: 9).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func smallYellowButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(RoundedRectangle(cornerRadius: 9).fill(Theme.ctaYellow))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func loadMetadata(force: Bool) async {
        guard let bookmark, bookmark.url != nil else { return }
        if !force, bookmark.metadataState != .pending {
            return
        }
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await store.refreshMetadata(for: bookmarkID, force: force)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        return formatter
    }()

    private static func dateText(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}

extension Bookmark {
    var displayInitial: String {
        let name = sourceName ?? domain
        guard let first = name.first(where: { $0.isLetter || $0.isNumber }) else { return "?" }
        return String(first).uppercased()
    }

    var sourceLabel: String {
        sourceName ?? domain
    }

    var displayDomain: String {
        guard let url, let host = url.host else { return domain }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

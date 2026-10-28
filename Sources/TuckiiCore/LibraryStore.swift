import Foundation
import Combine

public struct LibraryStats: Equatable {
    public var collections: Int
    public var saves: Int
    public var pinned: Int
    public var tags: Int

    public init(collections: Int, saves: Int, pinned: Int, tags: Int) {
        self.collections = collections
        self.saves = saves
        self.pinned = pinned
        self.tags = tags
    }
}

public struct UsageSummary: Equatable {
    public var linksUsed: Int
    public var linksLimit: Int?
    public var imagesUsed: Int
    public var imagesLimit: Int?
    public var collectionsUsed: Int
    public var collectionsLimit: Int?
    public var resetsAt: Date
}

public final class LibraryStore: ObservableObject {
    private struct Snapshot: Codable {
        var version: Int
        var collections: [TuckiiCollection]
        var bookmarks: [Bookmark]
        var tags: [Tag]
        var settings: LibrarySettings
        var usage: DailyUsage
    }

    @Published public internal(set) var collections: [TuckiiCollection]
    @Published public internal(set) var bookmarks: [Bookmark]
    @Published public internal(set) var tags: [Tag]
    @Published public internal(set) var settings: LibrarySettings
    @Published public internal(set) var usage: DailyUsage

    private let storageURL: URL

    public init(storageURL: URL = LibraryStore.defaultStorageURL()) {
        self.storageURL = storageURL
        if let data = try? Data(contentsOf: storageURL),
           let snapshot = try? Self.makeDecoder().decode(Snapshot.self, from: data) {
            self.collections = snapshot.collections
            self.bookmarks = snapshot.bookmarks
            self.tags = snapshot.tags
            self.settings = snapshot.settings
            self.usage = snapshot.usage
        } else {
            self.collections = [.unsorted()]
            self.bookmarks = []
            self.tags = []
            self.settings = LibrarySettings()
            self.usage = DailyUsage(dayKey: DailyUsage.dayKey(for: Date()))
        }
        if !collections.contains(where: { $0.isSystem }) {
            collections.insert(.unsorted(), at: 0)
        }
    }

    public static func defaultStorageURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("Tuckii", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("library.json")
    }

    public var isPro: Bool { settings.proSimulated }

    public var unsorted: TuckiiCollection {
        collections.first(where: { $0.isSystem }) ?? TuckiiCollection.unsorted()
    }

    public func collection(_ id: UUID) -> TuckiiCollection? {
        collections.first { $0.id == id }
    }

    public func bookmark(_ id: UUID) -> Bookmark? {
        bookmarks.first { $0.id == id }
    }

    public var visibleCollections: [TuckiiCollection] {
        sortCollections(
            collections.filter { collection in
                !collection.isSystem || bookmarkCount(in: collection.id) > 0
            }
        )
    }

    public var subcollectionCount: Int {
        collections.filter { $0.parentID != nil }.count
    }

    public func subcollections(of collectionID: UUID) -> [TuckiiCollection] {
        sortCollections(collections.filter { $0.parentID == collectionID })
    }

    public func bookmarkCount(in collectionID: UUID) -> Int {
        bookmarks.filter { $0.collectionID == collectionID }.count
    }

    public func unseenCount(in collectionID: UUID) -> Int {
        bookmarks.filter { $0.collectionID == collectionID && !$0.isSeen }.count
    }

    public var totalUnseenCount: Int {
        bookmarks.filter { !$0.isSeen }.count
    }

    public var stats: LibraryStats {
        LibraryStats(
            collections: collections.count,
            saves: bookmarks.count,
            pinned: bookmarks.filter(\.isPinned).count,
            tags: tags.count
        )
    }

    public func usageSummary(now: Date = Date()) -> UsageSummary {
        let rolled = usage.rolled(to: now)
        let free = !isPro
        let nonSystemCollections = collections.filter { !$0.isSystem }.count
        return UsageSummary(
            linksUsed: rolled.links,
            linksLimit: free ? FreeLimits.linksPerDay : nil,
            imagesUsed: rolled.images,
            imagesLimit: free ? FreeLimits.imagesPerDay : nil,
            collectionsUsed: nonSystemCollections,
            collectionsLimit: free ? FreeLimits.collections : nil,
            resetsAt: DailyUsage.nextReset(after: now)
        )
    }

    public func refreshUsage(now: Date = Date()) {
        let rolled = usage.rolled(to: now)
        if rolled != usage {
            usage = rolled
            persist()
        }
    }

    @discardableResult
    public func createCollection(
        name: String,
        colorHex: UInt32,
        icon: TuckiiCollection.Icon = .folder,
        parentID: UUID? = nil,
        now: Date = Date()
    ) throws -> TuckiiCollection {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LibraryError.invalidName }
        if let parentID, collection(parentID) == nil {
            throw LibraryError.collectionNotFound
        }
        if parentID != nil, !isPro {
            throw LibraryError.proRequired(.subCollections)
        }
        let nonSystemCount = collections.filter { !$0.isSystem }.count
        if !isPro, nonSystemCount >= FreeLimits.collections {
            throw LibraryError.proRequired(.extraCollection)
        }
        let collection = TuckiiCollection(
            name: trimmed,
            colorHex: colorHex,
            icon: icon,
            parentID: parentID,
            createdAt: now,
            updatedAt: now
        )
        collections.append(collection)
        persist()
        return collection
    }

    public func deleteCollection(_ id: UUID) throws {
        guard let index = collections.firstIndex(where: { $0.id == id }) else {
            throw LibraryError.collectionNotFound
        }
        guard !collections[index].isSystem else { return }
        for bookmarkIndex in bookmarks.indices where bookmarks[bookmarkIndex].collectionID == id {
            bookmarks[bookmarkIndex].collectionID = unsorted.id
        }
        let parentID = collections[index].parentID
        for childIndex in collections.indices where collections[childIndex].parentID == id {
            collections[childIndex].parentID = parentID
        }
        collections.remove(at: index)
        persist()
    }

    @discardableResult
    public func addBookmark(
        url: URL,
        to collectionID: UUID? = nil,
        isPinned: Bool = false,
        kind: Bookmark.Kind = .link,
        now: Date = Date()
    ) throws -> Bookmark {
        refreshUsage(now: now)
        let targetID = collectionID ?? unsorted.id
        guard collection(targetID) != nil else { throw LibraryError.collectionNotFound }
        if !isPro {
            switch kind {
            case .link where usage.links >= FreeLimits.linksPerDay:
                throw LibraryError.proRequired(.dailyLinks)
            case .image where usage.images >= FreeLimits.imagesPerDay:
                throw LibraryError.proRequired(.dailyImages)
            default:
                break
            }
        }
        let domain = Self.displayDomain(for: url)
        let bookmark = Bookmark(
            kind: kind,
            url: url,
            title: url.absoluteString,
            domain: domain,
            placeholderSeed: StableHash.fnv1a(domain),
            collectionID: targetID,
            isPinned: isPinned,
            createdAt: now,
            updatedAt: now
        )
        bookmarks.append(bookmark)
        usage.record(kind)
        persist()
        return bookmark
    }

    public func applyMetadata(_ metadata: LinkMetadata, to bookmarkID: UUID, now: Date = Date()) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) else { return }
        var bookmark = bookmarks[index]
        if let title = metadata.title, !title.isEmpty {
            bookmark.title = title
        }
        if let summary = metadata.summary, !summary.isEmpty {
            bookmark.summary = summary
        }
        if let siteName = metadata.siteName, !siteName.isEmpty {
            bookmark.sourceName = siteName
        }
        bookmark.imageURL = metadata.imageURL
        bookmark.faviconURL = metadata.faviconURL
        bookmark.metadataState = .ready
        bookmark.updatedAt = now
        bookmarks[index] = bookmark
        persist()
    }

    public func markMetadataFailed(_ bookmarkID: UUID, now: Date = Date()) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) else { return }
        bookmarks[index].metadataState = .failed
        bookmarks[index].updatedAt = now
        persist()
    }

    @MainActor
    public func refreshMetadata(for bookmarkID: UUID, force: Bool = false) async {
        guard let bookmark = bookmark(bookmarkID), let url = bookmark.url else { return }
        if !force, bookmark.metadataState != .pending {
            return
        }
        do {
            let metadata = try await MetadataScraper().fetch(from: url)
            applyMetadata(metadata, to: bookmarkID)
        } catch {
            markMetadataFailed(bookmarkID)
        }
    }

    public func updateTitle(_ title: String, for bookmarkID: UUID, now: Date = Date()) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        bookmarks[index].title = trimmed
        bookmarks[index].updatedAt = now
        persist()
    }

    public func updateNotes(_ notes: String, for bookmarkID: UUID, now: Date = Date()) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) else { return }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        bookmarks[index].notes = trimmed.isEmpty ? nil : trimmed
        bookmarks[index].updatedAt = now
        persist()
    }

    public func togglePin(_ bookmarkID: UUID, now: Date = Date()) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) else { return }
        bookmarks[index].isPinned.toggle()
        bookmarks[index].updatedAt = now
        persist()
    }

    public func markSeen(_ bookmarkID: UUID, now: Date = Date()) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }),
              !bookmarks[index].isSeen else { return }
        bookmarks[index].isSeen = true
        bookmarks[index].updatedAt = now
        persist()
    }

    public func markAllSeen(in collectionID: UUID, now: Date = Date()) {
        var changed = false
        for index in bookmarks.indices where bookmarks[index].collectionID == collectionID && !bookmarks[index].isSeen {
            bookmarks[index].isSeen = true
            bookmarks[index].updatedAt = now
            changed = true
        }
        if changed { persist() }
    }

    public func move(_ bookmarkID: UUID, to collectionID: UUID, now: Date = Date()) throws {
        guard collection(collectionID) != nil else { throw LibraryError.collectionNotFound }
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) else {
            throw LibraryError.bookmarkNotFound
        }
        bookmarks[index].collectionID = collectionID
        bookmarks[index].updatedAt = now
        persist()
    }

    public func deleteBookmark(_ bookmarkID: UUID) {
        bookmarks.removeAll { $0.id == bookmarkID }
        persist()
    }

    public func deleteBookmarks(_ ids: Set<UUID>) {
        bookmarks.removeAll { ids.contains($0.id) }
        persist()
    }

    public func sortedBookmarks(in collectionID: UUID) -> [Bookmark] {
        sortSaves(
            bookmarks.filter { $0.collectionID == collectionID },
            by: collection(collectionID)?.saveSort ?? .newestFirst
        )
    }

    public func pinnedBookmarks(in collectionID: UUID) -> [Bookmark] {
        sortedBookmarks(in: collectionID).filter(\.isPinned)
    }

    public func unpinnedBookmarks(in collectionID: UUID) -> [Bookmark] {
        sortedBookmarks(in: collectionID).filter { !$0.isPinned }
    }

    public func search(_ query: String) -> [Bookmark] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let results = bookmarks.filter { bookmark in
            bookmark.title.localizedCaseInsensitiveContains(trimmed)
                || (bookmark.summary?.localizedCaseInsensitiveContains(trimmed) ?? false)
                || (bookmark.url?.absoluteString.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
        return sortSaves(results, by: .newestFirst)
    }

    public func recentlySaved(limit: Int = 6) -> [Bookmark] {
        Array(sortSaves(bookmarks, by: .newestFirst).prefix(limit))
    }

    public func setCollectionSort(_ sort: CollectionSort) {
        settings.collectionSort = sort
        persist()
    }

    public func setSaveSort(_ sort: SaveSort, for collectionID: UUID) {
        guard let index = collections.firstIndex(where: { $0.id == collectionID }) else { return }
        collections[index].saveSort = sort
        persist()
    }

    public func setDarkMode(_ enabled: Bool) {
        settings.darkMode = enabled
        persist()
    }

    public func setHapticsEnabled(_ enabled: Bool) {
        settings.hapticsEnabled = enabled
        persist()
    }

    public func setRemindersEnabled(_ enabled: Bool) {
        settings.remindersEnabled = enabled
        persist()
    }

    public func setProSimulated(_ enabled: Bool) {
        settings.proSimulated = enabled
        persist()
    }

    @discardableResult
    public func addTag(named name: String, now: Date = Date()) throws -> Tag {
        guard isPro else { throw LibraryError.proRequired(.tags) }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LibraryError.invalidName }
        guard !tags.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) else {
            throw LibraryError.duplicateTag
        }
        let tag = Tag(name: trimmed, createdAt: now)
        tags.append(tag)
        persist()
        return tag
    }

    public func tags(for bookmarkID: UUID) -> [Tag] {
        guard let bookmark = bookmarks.first(where: { $0.id == bookmarkID }) else { return [] }
        return tags.filter { bookmark.tagIDs.contains($0.id) }
    }

    public func attachTag(_ tagID: UUID, to bookmarkID: UUID, now: Date = Date()) {
        guard tags.contains(where: { $0.id == tagID }),
              let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }),
              !bookmarks[index].tagIDs.contains(tagID)
        else { return }
        bookmarks[index].tagIDs.append(tagID)
        bookmarks[index].updatedAt = now
        persist()
    }

    public func detachTag(_ tagID: UUID, from bookmarkID: UUID, now: Date = Date()) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmarkID }) else { return }
        bookmarks[index].tagIDs.removeAll { $0 == tagID }
        bookmarks[index].updatedAt = now
        persist()
    }

    public func deleteAllData() {
        collections = [.unsorted()]
        bookmarks = []
        tags = []
        usage = DailyUsage(dayKey: DailyUsage.dayKey(for: Date()))
        persist()
    }

    public func seedDemoData(now: Date = Date()) {
        guard bookmarks.isEmpty, collections.count <= 1 else { return }
        let recipes = (try? createCollection(name: "Recipes", colorHex: 0xFFB020, icon: .coffee, now: now)) ?? unsorted
        let ideas = (try? createCollection(name: "Home ideas", colorHex: 0x22BFA6, icon: .heart, now: now.addingTimeInterval(1))) ?? unsorted
        let travel = (try? createCollection(name: "Travel", colorHex: 0x4E8DF5, icon: .plane, now: now.addingTimeInterval(2))) ?? unsorted

        if let url = URL(string: "https://social.example/reel/quick-dinner-recipe"),
           let bookmark = try? addBookmark(url: url, to: recipes.id, isPinned: true, now: now) {
            applyMetadata(
                LinkMetadata(
                    title: "Quick dinner recipe",
                    summary: "5 vegetables, 1 pan, 15 minutes.",
                    siteName: "social.example"
                ),
                to: bookmark.id,
                now: now
            )
        }

        if let url = URL(string: "https://pinterest.example/cozy-reading-corner"),
           let bookmark = try? addBookmark(url: url, to: ideas.id, now: now.addingTimeInterval(30)) {
            applyMetadata(
                LinkMetadata(
                    title: "Cozy reading corner ideas",
                    summary: "A lamp, a chair and a shelf. Everything else follows.",
                    siteName: "Pinterest"
                ),
                to: bookmark.id,
                now: now.addingTimeInterval(30)
            )
            markSeen(bookmark.id, now: now)
        }

        if let url = URL(string: "https://travel.example/kyoto-early"),
           let bookmark = try? addBookmark(url: url, to: travel.id, now: now.addingTimeInterval(60)) {
            applyMetadata(
                LinkMetadata(
                    title: "Kyoto travel tip: go early",
                    summary: "Visit Higashiyama at 7am to avoid the crowds.",
                    siteName: "travel.example"
                ),
                to: bookmark.id,
                now: now.addingTimeInterval(60)
            )
        }
    }

    private func sortCollections(_ input: [TuckiiCollection]) -> [TuckiiCollection] {
        switch settings.collectionSort {
        case .oldestFirst:
            return input.sorted { $0.createdAt < $1.createdAt }
        case .newestFirst:
            return input.sorted { $0.createdAt > $1.createdAt }
        case .nameAZ:
            return input.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .recentlySaved:
            return input.sorted { lhs, rhs in
                lastSaveDate(in: lhs.id) > lastSaveDate(in: rhs.id)
            }
        }
    }

    private func lastSaveDate(in collectionID: UUID) -> Date {
        let latest = bookmarks.filter { $0.collectionID == collectionID }.map(\.createdAt).max()
        return latest ?? collection(collectionID)?.createdAt ?? .distantPast
    }

    private func sortSaves(_ input: [Bookmark], by sort: SaveSort) -> [Bookmark] {
        switch sort {
        case .newestFirst:
            return input.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return input.sorted { $0.createdAt < $1.createdAt }
        case .titleAZ:
            return input.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .websiteAZ:
            return input.sorted { lhs, rhs in
                let comparison = lhs.domain.localizedCaseInsensitiveCompare(rhs.domain)
                if comparison == .orderedSame {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return comparison == .orderedAscending
            }
        }
    }

    private static func displayDomain(for url: URL) -> String {
        let host = url.host ?? url.absoluteString
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    func persist() {
        let snapshot = Snapshot(
            version: 1,
            collections: collections,
            bookmarks: bookmarks,
            tags: tags,
            settings: settings,
            usage: usage
        )
        guard let data = try? Self.makeEncoder().encode(snapshot) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

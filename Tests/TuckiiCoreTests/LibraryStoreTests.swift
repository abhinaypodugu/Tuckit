import XCTest
@testable import TuckiiCore

final class LibraryStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TuckiiTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() -> LibraryStore {
        LibraryStore(storageURL: directory.appendingPathComponent("library.json"))
    }

    private let day = Date(timeIntervalSince1970: 1_776_000_000)

    func testStartsWithImplicitUnsortedCollection() {
        let store = makeStore()
        XCTAssertEqual(store.collections.count, 1)
        XCTAssertEqual(store.unsorted.name, "Unsorted")
        XCTAssertTrue(store.visibleCollections.isEmpty)
    }

    func testUnsortedAppearsOnceItHasSaves() throws {
        let store = makeStore()
        let url = URL(string: "https://en.wikipedia.org/wiki/Dosa")!
        try store.addBookmark(url: url, now: day)
        XCTAssertEqual(store.visibleCollections.map(\.name), ["Unsorted"])
    }

    func testFreeCollectionLimit() throws {
        let store = makeStore()
        try store.createCollection(name: "Recipes", colorHex: 0xFFB020, now: day)
        try store.createCollection(name: "Ideas", colorHex: 0x4E8DF5, now: day)
        try store.createCollection(name: "Travel", colorHex: 0x27C4A8, now: day)
        XCTAssertThrowsError(try store.createCollection(name: "Fourth", colorHex: 0x222222, now: day)) { error in
            XCTAssertEqual(error as? LibraryError, .proRequired(.extraCollection))
        }
    }

    func testProUnlocksCollections() throws {
        let store = makeStore()
        store.setProSimulated(true)
        for index in 0..<6 {
            try store.createCollection(name: "Collection \(index)", colorHex: 0xFFB020, now: day)
        }
        XCTAssertEqual(store.collections.filter { !$0.isSystem }.count, 6)
    }

    func testFreeDailyLinkQuota() throws {
        let store = makeStore()
        let url = URL(string: "https://example.com/a")!
        for _ in 0..<FreeLimits.linksPerDay {
            try store.addBookmark(url: url, now: day)
        }
        XCTAssertThrowsError(try store.addBookmark(url: url, now: day)) { error in
            XCTAssertEqual(error as? LibraryError, .proRequired(.dailyLinks))
        }
        let nextDay = day.addingTimeInterval(86_400)
        XCTAssertNoThrow(try store.addBookmark(url: url, now: nextDay))
    }

    func testFreeDailyImageQuota() throws {
        let store = makeStore()
        store.setProSimulated(true)
        let url = URL(string: "https://example.com/img")!
        for _ in 0..<FreeLimits.imagesPerDay {
            try store.addBookmark(url: url, kind: .image, now: day)
        }
        store.setProSimulated(false)
        XCTAssertThrowsError(try store.addBookmark(url: url, kind: .image, now: day)) { error in
            XCTAssertEqual(error as? LibraryError, .proRequired(.dailyImages))
        }
    }

    func testPersistenceRoundTrip() throws {
        let store = makeStore()
        let url = URL(string: "https://example.com/article")!
        let bookmark = try store.addBookmark(url: url, now: day)
        store.updateNotes("Try the coconut chutney", for: bookmark.id, now: day)
        store.togglePin(bookmark.id, now: day)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.bookmarks.count, 1)
        XCTAssertEqual(reloaded.bookmarks.first?.notes, "Try the coconut chutney")
        XCTAssertEqual(reloaded.bookmarks.first?.isPinned, true)
    }

    func testMoveBookmarkBetweenCollections() throws {
        let store = makeStore()
        let recipes = try store.createCollection(name: "Recipes", colorHex: 0xFFB020, now: day)
        let bookmark = try store.addBookmark(url: URL(string: "https://example.com")!, now: day)
        try store.move(bookmark.id, to: recipes.id, now: day)
        XCTAssertEqual(store.bookmarks.first?.collectionID, recipes.id)
    }

    func testDeletingCollectionMovesBookmarksToUnsorted() throws {
        let store = makeStore()
        let recipes = try store.createCollection(name: "Recipes", colorHex: 0xFFB020, now: day)
        let bookmark = try store.addBookmark(url: URL(string: "https://example.com")!, to: recipes.id, now: day)
        try store.deleteCollection(recipes.id)
        XCTAssertEqual(store.bookmark(bookmark.id)?.collectionID, store.unsorted.id)
    }

    func testSeenStateAndStats() throws {
        let store = makeStore()
        let first = try store.addBookmark(url: URL(string: "https://a.example")!, now: day)
        _ = try store.addBookmark(url: URL(string: "https://b.example")!, now: day)
        XCTAssertEqual(store.totalUnseenCount, 2)
        store.markSeen(first.id, now: day)
        XCTAssertEqual(store.totalUnseenCount, 1)
        store.togglePin(first.id, now: day)
        XCTAssertEqual(store.stats, LibraryStats(collections: 1, saves: 2, pinned: 1, tags: 0))
    }

    func testSubcollectionsRequirePro() throws {
        let store = makeStore()
        let parent = try store.createCollection(name: "Travel", colorHex: 0xFFB020, now: day)
        XCTAssertThrowsError(try store.createCollection(name: "Japan", colorHex: 0x222222, parentID: parent.id, now: day)) { error in
            XCTAssertEqual(error as? LibraryError, .proRequired(.subCollections))
        }
        store.setProSimulated(true)
        let child = try store.createCollection(name: "Japan", colorHex: 0x222222, parentID: parent.id, now: day)
        XCTAssertEqual(store.subcollections(of: parent.id).map(\.id), [child.id])
    }

    func testTagsRequireProAndDedupe() throws {
        let store = makeStore()
        XCTAssertThrowsError(try store.addTag(named: "japan", now: day)) { error in
            XCTAssertEqual(error as? LibraryError, .proRequired(.tags))
        }
        store.setProSimulated(true)
        let tag = try store.addTag(named: "japan", now: day)
        XCTAssertEqual(tag.name, "japan")
        XCTAssertThrowsError(try store.addTag(named: "JAPAN", now: day))
    }

    func testDeleteAllDataResetsLibrary() throws {
        let store = makeStore()
        try store.createCollection(name: "Recipes", colorHex: 0xFFB020, now: day)
        _ = try store.addBookmark(url: URL(string: "https://example.com")!, now: day)
        store.deleteAllData()
        XCTAssertEqual(store.collections.count, 1)
        XCTAssertTrue(store.bookmarks.isEmpty)
        XCTAssertTrue(store.tags.isEmpty)
        XCTAssertEqual(store.usage.links, 0)
    }

    func testUpdateCollection() throws {
        let store = makeStore()
        let collection = try store.createCollection(name: "Recipies", colorHex: 0x111111, now: day)
        try store.updateCollection(collection.id, name: "Recipes", colorHex: 0xFFB020, icon: .coffee, now: day)
        XCTAssertEqual(store.collection(collection.id)?.name, "Recipes")
        XCTAssertEqual(store.collection(collection.id)?.colorHex, 0xFFB020)
        XCTAssertEqual(store.collection(collection.id)?.icon, .coffee)
        XCTAssertThrowsError(try store.updateCollection(collection.id, name: "   ", colorHex: 0, icon: .folder, now: day))
    }

    func testSeedDemoData() {
        let store = makeStore()
        store.seedDemoData(now: day)
        XCTAssertEqual(store.collections.filter { !$0.isSystem }.count, 3)
        XCTAssertEqual(
            store.collections.filter { !$0.isSystem }.map(\.name).sorted(),
            ["Home ideas", "Recipes", "Travel"]
        )
        XCTAssertEqual(store.bookmarks.count, 3)
        XCTAssertEqual(store.bookmarks.filter(\.isPinned).count, 1)
        XCTAssertEqual(store.totalUnseenCount, 2)
        XCTAssertEqual(store.stats.pinned, 1)
    }
}

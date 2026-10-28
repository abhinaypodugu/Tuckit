import XCTest
@testable import TuckiiCore

final class SortingAndSearchTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TuckiiSortTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() -> LibraryStore {
        LibraryStore(storageURL: directory.appendingPathComponent("library.json"))
    }

    private let base = Date(timeIntervalSince1970: 1_776_000_000)

    func testSaveSortOrders() throws {
        let store = makeStore()
        let older = try store.addBookmark(url: URL(string: "https://zeta.example/one")!, now: base)
        let newer = try store.addBookmark(url: URL(string: "https://alpha.example/two")!, now: base.addingTimeInterval(60))
        store.updateTitle("Beta", for: older.id, now: base)
        store.updateTitle("Alpha", for: newer.id, now: base)

        store.setSaveSort(.newestFirst, for: store.unsorted.id)
        XCTAssertEqual(store.sortedBookmarks(in: store.unsorted.id).map(\.id), [newer.id, older.id])

        store.setSaveSort(.oldestFirst, for: store.unsorted.id)
        XCTAssertEqual(store.sortedBookmarks(in: store.unsorted.id).map(\.id), [older.id, newer.id])

        store.setSaveSort(.titleAZ, for: store.unsorted.id)
        XCTAssertEqual(store.sortedBookmarks(in: store.unsorted.id).map(\.title), ["Alpha", "Beta"])

        store.setSaveSort(.websiteAZ, for: store.unsorted.id)
        XCTAssertEqual(store.sortedBookmarks(in: store.unsorted.id).map(\.domain), ["alpha.example", "zeta.example"])
    }

    func testPinnedBookmarksAreSeparated() throws {
        let store = makeStore()
        let pinned = try store.addBookmark(url: URL(string: "https://a.example")!, isPinned: true, now: base)
        let plain = try store.addBookmark(url: URL(string: "https://b.example")!, now: base.addingTimeInterval(10))
        XCTAssertEqual(store.pinnedBookmarks(in: store.unsorted.id).map(\.id), [pinned.id])
        XCTAssertEqual(store.unpinnedBookmarks(in: store.unsorted.id).map(\.id), [plain.id])
    }

    func testCollectionSortOrders() throws {
        let store = makeStore()
        let first = try store.createCollection(name: "Zeta", colorHex: 0xFFB020, now: base)
        let second = try store.createCollection(name: "Alpha", colorHex: 0x4E8DF5, now: base.addingTimeInterval(30))
        try store.addBookmark(url: URL(string: "https://example.com/unsorted")!, now: base.addingTimeInterval(1))
        let firstBookmark = try store.addBookmark(url: URL(string: "https://example.com/first")!, to: first.id, now: base.addingTimeInterval(5))
        try store.addBookmark(url: URL(string: "https://example.com/second")!, to: second.id, now: base.addingTimeInterval(90))

        store.setCollectionSort(.oldestFirst)
        XCTAssertEqual(store.visibleCollections.map(\.id), [first.id, second.id, store.unsorted.id])

        store.setCollectionSort(.newestFirst)
        XCTAssertEqual(store.visibleCollections.map(\.id), [store.unsorted.id, second.id, first.id])

        store.setCollectionSort(.nameAZ)
        XCTAssertEqual(store.visibleCollections.map(\.name), ["Alpha", "Unsorted", "Zeta"])

        store.setCollectionSort(.recentlySaved)
        XCTAssertEqual(store.visibleCollections.map(\.id), [second.id, first.id, store.unsorted.id])
        XCTAssertEqual(store.bookmarkCount(in: first.id), 1)
        XCTAssertEqual(firstBookmark.collectionID, first.id)
    }

    func testSearchMatchesTitleSummaryAndURL() throws {
        let store = makeStore()
        let target = try store.addBookmark(url: URL(string: "https://social.example/reel/quick-dinner")!, now: base)
        store.updateTitle("Quick dinner recipe", for: target.id, now: base)
        store.updateNotes("five vegetables", for: target.id, now: base)
        _ = try store.addBookmark(url: URL(string: "https://travel.example/kyoto")!, now: base.addingTimeInterval(5))

        XCTAssertEqual(store.search("dinner").map(\.id), [target.id])
        XCTAssertEqual(store.search("QUICK-DINNER").map(\.id), [target.id])
        XCTAssertEqual(store.search("kyoto").count, 1)
        XCTAssertTrue(store.search("   ").isEmpty)
        XCTAssertTrue(store.search("no-match-here").isEmpty)
    }

    func testUsageSummaryLimitsAndReset() throws {
        let store = makeStore()
        _ = try store.addBookmark(url: URL(string: "https://a.example")!, now: base)
        let summary = store.usageSummary(now: base)
        XCTAssertEqual(summary.linksUsed, 1)
        XCTAssertEqual(summary.linksLimit, 4)
        XCTAssertEqual(summary.collectionsLimit, 3)
        XCTAssertEqual(summary.resetsAt, DailyUsage.nextReset(after: base))

        store.setProSimulated(true)
        let proSummary = store.usageSummary(now: base)
        XCTAssertNil(proSummary.linksLimit)
        XCTAssertNil(proSummary.collectionsLimit)
    }

    func testURLNormalizer() {
        XCTAssertEqual(URLNormalizer.normalize("example.com/path")?.absoluteString, "https://example.com/path")
        XCTAssertEqual(URLNormalizer.normalize("https://example.com")?.host, "example.com")
        XCTAssertNil(URLNormalizer.normalize(""))
        XCTAssertNil(URLNormalizer.normalize("not a url"))
        XCTAssertNil(URLNormalizer.normalize("   "))
    }
}

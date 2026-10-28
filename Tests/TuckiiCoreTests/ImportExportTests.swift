import XCTest
@testable import TuckiiCore

final class ImportExportTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TuckiiImportTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() -> LibraryStore {
        LibraryStore(storageURL: directory.appendingPathComponent("library.json"))
    }

    private let day = Date(timeIntervalSince1970: 1_776_000_000)

    func testParsesCSVWithHeaderAndQuotes() throws {
        let csv = """
        url,title,folder
        https://example.com/a,"Dosa, with chutney",Recipes
        https://example.com/b,Simple loaf,
        """
        let items = try BookmarkFileParser.parse(data: Data(csv.utf8), fileExtension: "csv")
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "Dosa, with chutney")
        XCTAssertEqual(items[0].folder, "Recipes")
        XCTAssertNil(items[1].folder)
    }

    func testParsesCSVWithoutHeader() throws {
        let csv = "https://example.com/a,Title A\nhttps://example.com/b,Title B\n"
        let items = try BookmarkFileParser.parse(data: Data(csv.utf8), fileExtension: "csv")
        XCTAssertEqual(items.map(\.title), ["Title A", "Title B"])
    }

    func testParsesHTMLBookmarksWithFolders() throws {
        let html = """
        <!DOCTYPE NETSCAPE-Bookmark-file-1>
        <DL><p>
          <DT><H3>Recipes</H3>
          <DL><p>
            <DT><A HREF="https://example.com/dosa">Dosa &amp; chutney</A>
            <DT><A HREF="https://example.com/idli">Idli recipe</A>
          </DL><p>
          <DT><H3>Travel</H3>
          <DL><p>
            <DT><A HREF="https://example.com/kyoto">Kyoto tip</A>
          </DL><p>
        </DL><p>
        """
        let items = try BookmarkFileParser.parse(data: Data(html.utf8), fileExtension: "html")
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].folder, "Recipes")
        XCTAssertEqual(items[0].title, "Dosa & chutney")
        XCTAssertEqual(items[2].folder, "Travel")
    }

    func testGenericJSONImport() throws {
        let json = """
        [{"url": "https://example.com/a", "title": "Example A", "folder": "Recipes"}]
        """
        let items = try BookmarkFileParser.parse(data: Data(json.utf8), fileExtension: "json")
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].folder, "Recipes")
    }

    func testUnsupportedFormatThrows() {
        XCTAssertThrowsError(try BookmarkFileParser.parse(data: Data(), fileExtension: "txt"))
    }

    func testExportImportRoundTrip() throws {
        let store = makeStore()
        store.setProSimulated(true)
        let recipes = try store.createCollection(name: "Recipes", colorHex: 0xFFB020, now: day)
        let bookmark = try store.addBookmark(url: URL(string: "https://example.com/dosa")!, to: recipes.id, isPinned: true, now: day)
        store.updateTitle("Dosa recipe", for: bookmark.id, now: day)
        store.updateNotes("Use ghee", for: bookmark.id, now: day)

        guard let backup = store.exportBackupData(now: day) else {
            return XCTFail("export failed")
        }

        let fresh = LibraryStore(storageURL: directory.appendingPathComponent("fresh.json"))
        let result = try fresh.importBookmarks(from: backup, fileExtension: "json", now: day)
        XCTAssertEqual(result.imported, 1)
        XCTAssertEqual(result.collectionsCreated, 1)
        XCTAssertEqual(fresh.bookmarks.first?.title, "Dosa recipe")
        XCTAssertEqual(fresh.bookmarks.first?.notes, "Use ghee")
        XCTAssertEqual(fresh.bookmarks.first?.isPinned, true)
        XCTAssertEqual(fresh.collection(fresh.bookmarks.first!.collectionID)?.name, "Recipes")
    }

    func testImportDeduplicatesByURL() throws {
        let store = makeStore()
        let items = [
            ImportedBookmark(url: URL(string: "https://example.com/a")!, title: "A"),
            ImportedBookmark(url: URL(string: "https://example.com/a")!, title: "A again"),
        ]
        let first = store.importBookmarks(items, now: day)
        XCTAssertEqual(first.imported, 1)
        XCTAssertEqual(first.skipped, 1)
        let second = store.importBookmarks(items, now: day)
        XCTAssertEqual(second.imported, 0)
        XCTAssertEqual(second.skipped, 2)
        XCTAssertEqual(store.bookmarks.count, 1)
    }

    func testImportCreatesFoldersAndRespectsFreeCollectionLimit() throws {
        let store = makeStore()
        try store.createCollection(name: "One", colorHex: 0x111111, now: day)
        try store.createCollection(name: "Two", colorHex: 0x222222, now: day)
        try store.createCollection(name: "Three", colorHex: 0x333333, now: day)
        let items = [
            ImportedBookmark(url: URL(string: "https://example.com/a")!, folder: "New Folder"),
        ]
        let result = store.importBookmarks(items, now: day)
        XCTAssertEqual(result.collectionsCreated, 0)
        XCTAssertEqual(store.collections.count, 4)
        XCTAssertEqual(store.bookmarks.first?.collectionID, store.unsorted.id)
    }
}

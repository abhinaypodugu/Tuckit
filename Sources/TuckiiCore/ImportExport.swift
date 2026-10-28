import Foundation

public struct ImportedBookmark: Equatable {
    public var url: URL
    public var title: String?
    public var folder: String?
    public var summary: String?
    public var sourceName: String?
    public var notes: String?
    public var tags: [String]
    public var isPinned: Bool
    public var isSeen: Bool
    public var createdAt: Date?

    public init(
        url: URL,
        title: String? = nil,
        folder: String? = nil,
        summary: String? = nil,
        sourceName: String? = nil,
        notes: String? = nil,
        tags: [String] = [],
        isPinned: Bool = false,
        isSeen: Bool = false,
        createdAt: Date? = nil
    ) {
        self.url = url
        self.title = title
        self.folder = folder
        self.summary = summary
        self.sourceName = sourceName
        self.notes = notes
        self.tags = tags
        self.isPinned = isPinned
        self.isSeen = isSeen
        self.createdAt = createdAt
    }
}

public struct ImportResult: Equatable {
    public var imported: Int
    public var skipped: Int
    public var collectionsCreated: Int

    public init(imported: Int, skipped: Int, collectionsCreated: Int) {
        self.imported = imported
        self.skipped = skipped
        self.collectionsCreated = collectionsCreated
    }
}

public enum ImportError: Error, Equatable {
    case unsupportedFormat
    case unreadableFile
}

public struct TuckiiBackup: Codable, Equatable {
    public struct BackupCollection: Codable, Equatable {
        public var name: String
        public var colorHex: UInt32
        public var icon: String
        public var createdAt: Date
    }

    public struct BackupBookmark: Codable, Equatable {
        public var url: String?
        public var title: String
        public var summary: String?
        public var sourceName: String?
        public var domain: String
        public var collectionName: String
        public var isPinned: Bool
        public var isSeen: Bool
        public var notes: String?
        public var tags: [String]
        public var createdAt: Date
    }

    public var version: Int
    public var exportedAt: Date
    public var collections: [BackupCollection]
    public var bookmarks: [BackupBookmark]
    public var tags: [String]

    public init(
        version: Int = 1,
        exportedAt: Date,
        collections: [BackupCollection],
        bookmarks: [BackupBookmark],
        tags: [String]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.collections = collections
        self.bookmarks = bookmarks
        self.tags = tags
    }
}

public enum BookmarkFileParser {
    public static func parse(data: Data, fileExtension: String) throws -> [ImportedBookmark] {
        switch fileExtension.lowercased() {
        case "json":
            return try parseJSON(data)
        case "html", "htm":
            return parseHTML(String(decoding: data, as: UTF8.self))
        case "csv":
            return parseCSV(String(decoding: data, as: UTF8.self))
        default:
            throw ImportError.unsupportedFormat
        }
    }

    private static func parseJSON(_ data: Data) throws -> [ImportedBookmark] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let backup = try? decoder.decode(TuckiiBackup.self, from: data) {
            return backup.bookmarks.compactMap { entry in
                guard let urlString = entry.url, let url = URL(string: urlString) else { return nil }
                return ImportedBookmark(
                    url: url,
                    title: entry.title,
                    folder: entry.collectionName,
                    summary: entry.summary,
                    sourceName: entry.sourceName,
                    notes: entry.notes,
                    tags: entry.tags,
                    isPinned: entry.isPinned,
                    isSeen: entry.isSeen,
                    createdAt: entry.createdAt
                )
            }
        }

        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            throw ImportError.unreadableFile
        }
        guard let array = object as? [[String: Any]] else {
            throw ImportError.unreadableFile
        }
        return array.compactMap { entry in
            let urlString = (entry["url"] as? String) ?? (entry["link"] as? String) ?? (entry["href"] as? String)
            guard let urlString, let url = URL(string: urlString) else { return nil }
            return ImportedBookmark(
                url: url,
                title: (entry["title"] as? String) ?? (entry["name"] as? String),
                folder: (entry["folder"] as? String) ?? (entry["collection"] as? String)
            )
        }
    }

    private static func parseHTML(_ html: String) -> [ImportedBookmark] {
        let pattern = "(?is)<h3[^>]*>(.*?)</h3>|<a\\s[^>]*href=[\"']([^\"']+)[\"'][^>]*>(.*?)</a>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        var currentFolder: String?
        var results: [ImportedBookmark] = []
        for match in regex.matches(in: html, options: [], range: range) {
            if let folderRange = Range(match.range(at: 1), in: html) {
                let folder = stripTags(String(html[folderRange]))
                currentFolder = folder.isEmpty ? nil : folder
                continue
            }
            guard let urlRange = Range(match.range(at: 2), in: html),
                  let titleRange = Range(match.range(at: 3), in: html),
                  let url = URL(string: decodeEntities(String(html[urlRange])))
            else { continue }
            let title = stripTags(String(html[titleRange]))
            results.append(
                ImportedBookmark(
                    url: url,
                    title: title.isEmpty ? nil : title,
                    folder: currentFolder
                )
            )
        }
        return results
    }

    private static func parseCSV(_ text: String) -> [ImportedBookmark] {
        let rows = text
            .split(whereSeparator: { $0 == "\n" || $0 == "\r\n" })
            .map { parseCSVLine(String($0)) }
            .filter { !$0.isEmpty }
        guard !rows.isEmpty else { return [] }

        var header: [String]?
        if let first = rows.first,
           first.contains(where: { $0.lowercased() == "url" || $0.lowercased() == "link" }) {
            header = first.map { $0.lowercased() }
        }
        let startIndex = header == nil ? 0 : 1

        func value(_ row: [String], _ names: [String]) -> String? {
            guard let header else { return nil }
            for name in names {
                if let index = header.firstIndex(of: name), index < row.count {
                    let trimmed = row[index].trimmingCharacters(in: .whitespaces)
                    return trimmed.isEmpty ? nil : trimmed
                }
            }
            return nil
        }

        var results: [ImportedBookmark] = []
        for row in rows.dropFirst(startIndex) {
            let urlString: String?
            let title: String?
            let folder: String?
            if header != nil {
                urlString = value(row, ["url", "link", "href"])
                title = value(row, ["title", "name"])
                folder = value(row, ["folder", "collection", "category"])
            } else {
                urlString = row.first
                title = row.count > 1 ? row[1] : nil
                folder = row.count > 2 ? row[2] : nil
            }
            guard let urlString, let url = URL(string: urlString) else { continue }
            results.append(
                ImportedBookmark(
                    url: url,
                    title: title?.isEmpty == false ? title : nil,
                    folder: folder?.isEmpty == false ? folder : nil
                )
            )
        }
        return results
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var insideQuotes = false
        var iterator = line.makeIterator()
        while let character = iterator.next() {
            if character == "\"" {
                if insideQuotes {
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else {
                            insideQuotes = false
                            if next == "," {
                                fields.append(current)
                                current = ""
                            } else {
                                current.append(next)
                            }
                        }
                    } else {
                        insideQuotes = false
                    }
                } else {
                    insideQuotes = true
                }
            } else if character == "," && !insideQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        fields.append(current)
        return fields.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func stripTags(_ text: String) -> String {
        decodeEntities(text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
    }

    private static func decodeEntities(_ text: String) -> String {
        var output = text
        let entities = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&nbsp;": " ",
        ]
        for (entity, replacement) in entities {
            output = output.replacingOccurrences(of: entity, with: replacement)
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension LibraryStore {
    public func exportBackupData(now: Date = Date()) -> Data? {
        let backup = TuckiiBackup(
            exportedAt: now,
            collections: collections
                .filter { !$0.isSystem }
                .map {
                    TuckiiBackup.BackupCollection(
                        name: $0.name,
                        colorHex: $0.colorHex,
                        icon: $0.icon.rawValue,
                        createdAt: $0.createdAt
                    )
                },
            bookmarks: bookmarks.map { bookmark in
                TuckiiBackup.BackupBookmark(
                    url: bookmark.url?.absoluteString,
                    title: bookmark.title,
                    summary: bookmark.summary,
                    sourceName: bookmark.sourceName,
                    domain: bookmark.domain,
                    collectionName: collection(bookmark.collectionID)?.name ?? "Unsorted",
                    isPinned: bookmark.isPinned,
                    isSeen: bookmark.isSeen,
                    notes: bookmark.notes,
                    tags: tags.filter { bookmark.tagIDs.contains($0.id) }.map(\.name),
                    createdAt: bookmark.createdAt
                )
            },
            tags: tags.map(\.name)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(backup)
    }

    @discardableResult
    public func importBookmarks(from data: Data, fileExtension: String, now: Date = Date()) throws -> ImportResult {
        let items = try BookmarkFileParser.parse(data: data, fileExtension: fileExtension)
        return importBookmarks(items, now: now)
    }

    @discardableResult
    public func importBookmarks(_ items: [ImportedBookmark], now: Date = Date()) -> ImportResult {
        var imported = 0
        var skipped = 0
        var collectionsCreated = 0
        var seenURLs = Set(bookmarks.compactMap { $0.url?.absoluteString })
        var collectionIDByName: [String: UUID] = [:]
        for collection in collections {
            collectionIDByName[collection.name.lowercased()] = collection.id
        }
        var tagIDByName: [String: UUID] = [:]
        for tag in tags {
            tagIDByName[tag.name.lowercased()] = tag.id
        }

        for item in items {
            let urlString = item.url.absoluteString
            guard !seenURLs.contains(urlString) else {
                skipped += 1
                continue
            }
            seenURLs.insert(urlString)

            var targetCollectionID = unsorted.id
            if let folder = item.folder?.trimmingCharacters(in: .whitespacesAndNewlines), !folder.isEmpty,
               folder.lowercased() != "unsorted" {
                if let existing = collectionIDByName[folder.lowercased()] {
                    targetCollectionID = existing
                } else {
                    let nonSystemCount = collections.filter { !$0.isSystem }.count
                    if isPro || nonSystemCount < FreeLimits.collections,
                       let newCollection = try? createCollection(name: folder, colorHex: 0x9CD94E, now: now) {
                        targetCollectionID = newCollection.id
                        collectionIDByName[folder.lowercased()] = newCollection.id
                        collectionsCreated += 1
                    }
                }
            }

            let host = item.url.host ?? item.url.absoluteString
            let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            var bookmark = Bookmark(
                kind: .link,
                url: item.url,
                title: (item.title?.isEmpty == false ? item.title : nil) ?? item.url.absoluteString,
                summary: item.summary,
                sourceName: item.sourceName,
                domain: domain,
                placeholderSeed: StableHash.fnv1a(domain),
                collectionID: targetCollectionID,
                isPinned: item.isPinned,
                isSeen: item.isSeen,
                notes: item.notes,
                metadataState: (item.title?.isEmpty == false) ? .ready : .pending,
                createdAt: item.createdAt ?? now,
                updatedAt: now
            )

            if isPro {
                for tagName in item.tags {
                    let key = tagName.lowercased()
                    if let existingID = tagIDByName[key] {
                        if !bookmark.tagIDs.contains(existingID) {
                            bookmark.tagIDs.append(existingID)
                        }
                    } else if let newTag = try? addTag(named: tagName, now: now) {
                        tagIDByName[key] = newTag.id
                        bookmark.tagIDs.append(newTag.id)
                    }
                }
            }

            bookmarks.append(bookmark)
            imported += 1
        }

        persist()
        return ImportResult(imported: imported, skipped: skipped, collectionsCreated: collectionsCreated)
    }
}

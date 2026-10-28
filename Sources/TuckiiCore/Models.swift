import Foundation

public struct TuckiiCollection: Codable, Equatable, Identifiable {
    public enum Icon: String, Codable, CaseIterable {
        case folder, star, heart, book, music, camera, flag, moon, sun, cloud
        case pin, calendar, globe, gift, leaf, briefcase, cart, plane, car
        case coffee, film, headphones, palette, more
    }

    public static let unsortedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    public var id: UUID
    public var name: String
    public var colorHex: UInt32
    public var icon: Icon
    public var parentID: UUID?
    public var isSystem: Bool
    public var saveSort: SaveSort
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: UInt32,
        icon: Icon = .folder,
        parentID: UUID? = nil,
        isSystem: Bool = false,
        saveSort: SaveSort = .newestFirst,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.parentID = parentID
        self.isSystem = isSystem
        self.saveSort = saveSort
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static func unsorted(createdAt: Date = Date()) -> TuckiiCollection {
        TuckiiCollection(
            id: unsortedID,
            name: "Unsorted",
            colorHex: 0xBFC4CC,
            icon: .folder,
            isSystem: true,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}

public enum SaveSort: String, Codable, CaseIterable, Hashable {
    case newestFirst, oldestFirst, titleAZ, websiteAZ

    public var displayName: String {
        switch self {
        case .newestFirst: return "Newest first"
        case .oldestFirst: return "Oldest first"
        case .titleAZ: return "Title A–Z"
        case .websiteAZ: return "Website A–Z"
        }
    }
}

public enum CollectionSort: String, Codable, CaseIterable, Hashable {
    case oldestFirst, newestFirst, nameAZ, recentlySaved

    public var displayName: String {
        switch self {
        case .oldestFirst: return "Oldest first"
        case .newestFirst: return "Newest first"
        case .nameAZ: return "Name A–Z"
        case .recentlySaved: return "Recently saved"
        }
    }
}

public struct Bookmark: Codable, Equatable, Hashable, Identifiable {
    public enum Kind: String, Codable, Hashable {
        case link, image
    }

    public enum MetadataState: String, Codable, Hashable {
        case pending, ready, failed
    }

    public var id: UUID
    public var kind: Kind
    public var url: URL?
    public var title: String
    public var summary: String?
    public var sourceName: String?
    public var domain: String
    public var imageURL: URL?
    public var faviconURL: URL?
    public var placeholderSeed: UInt32
    public var collectionID: UUID
    public var isPinned: Bool
    public var isSeen: Bool
    public var notes: String?
    public var tagIDs: [UUID]
    public var metadataState: MetadataState
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        kind: Kind = .link,
        url: URL? = nil,
        title: String,
        summary: String? = nil,
        sourceName: String? = nil,
        domain: String,
        imageURL: URL? = nil,
        faviconURL: URL? = nil,
        placeholderSeed: UInt32 = 0,
        collectionID: UUID,
        isPinned: Bool = false,
        isSeen: Bool = false,
        notes: String? = nil,
        tagIDs: [UUID] = [],
        metadataState: MetadataState = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.url = url
        self.title = title
        self.summary = summary
        self.sourceName = sourceName
        self.domain = domain
        self.imageURL = imageURL
        self.faviconURL = faviconURL
        self.placeholderSeed = placeholderSeed
        self.collectionID = collectionID
        self.isPinned = isPinned
        self.isSeen = isSeen
        self.notes = notes
        self.tagIDs = tagIDs
        self.metadataState = metadataState
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Tag: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

public struct LibrarySettings: Codable, Equatable {
    public var collectionSort: CollectionSort
    public var darkMode: Bool
    public var hapticsEnabled: Bool
    public var remindersEnabled: Bool
    public var proSimulated: Bool

    public init(
        collectionSort: CollectionSort = .oldestFirst,
        darkMode: Bool = false,
        hapticsEnabled: Bool = true,
        remindersEnabled: Bool = false,
        proSimulated: Bool = false
    ) {
        self.collectionSort = collectionSort
        self.darkMode = darkMode
        self.hapticsEnabled = hapticsEnabled
        self.remindersEnabled = remindersEnabled
        self.proSimulated = proSimulated
    }
}

public enum StableHash {
    public static func fnv1a(_ string: String) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in string.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return hash
    }
}

public enum URLNormalizer {
    public static func normalize(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: candidate),
              let host = url.host,
              !host.isEmpty,
              host.contains(".")
        else { return nil }
        return url
    }
}

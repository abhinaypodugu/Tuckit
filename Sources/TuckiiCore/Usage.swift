import Foundation

public struct DailyUsage: Codable, Equatable {
    public var dayKey: String
    public var links: Int
    public var images: Int

    public init(dayKey: String, links: Int = 0, images: Int = 0) {
        self.dayKey = dayKey
        self.links = links
        self.images = images
    }

    public static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    public func rolled(to date: Date, calendar: Calendar = .current) -> DailyUsage {
        let key = Self.dayKey(for: date, calendar: calendar)
        guard key != dayKey else { return self }
        return DailyUsage(dayKey: key)
    }

    public mutating func record(_ kind: Bookmark.Kind) {
        switch kind {
        case .link: links += 1
        case .image: images += 1
        }
    }

    public static func nextReset(after date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: start) ?? date
    }
}

public enum FreeLimits {
    public static let linksPerDay = 4
    public static let imagesPerDay = 10
    public static let collections = 3
}

public enum ProFeature: Equatable {
    case tags
    case subCollections
    case shareCollection
    case exportBackup
    case cloudSync
    case dailyLinks
    case dailyImages
    case extraCollection

    public var gateMessage: String {
        switch self {
        case .tags: return "Tags is a Pro feature."
        case .subCollections: return "Subcollections is a Pro feature."
        case .shareCollection: return "Sharing collections is a Pro feature."
        case .exportBackup: return "Export & backup is a Pro feature."
        case .cloudSync: return "Cloud sync is a Pro feature."
        case .dailyLinks: return "You've hit today's free limit of 4 links."
        case .dailyImages: return "You've hit today's free limit of 10 images."
        case .extraCollection: return "Free accounts can have up to 3 collections."
        }
    }
}

public enum LibraryError: Error, Equatable {
    case invalidName
    case collectionNotFound
    case bookmarkNotFound
    case duplicateTag
    case proRequired(ProFeature)

    public var title: String {
        switch self {
        case .invalidName: return "Name required"
        case .collectionNotFound, .bookmarkNotFound: return "Not found"
        case .duplicateTag: return "Tag exists"
        case .proRequired: return "Go Pro"
        }
    }

    public var message: String {
        switch self {
        case .invalidName: return "Please enter a name for the collection."
        case .collectionNotFound: return "That collection no longer exists."
        case .bookmarkNotFound: return "That save no longer exists."
        case .duplicateTag: return "You already have a tag with that name."
        case .proRequired(let feature): return feature.gateMessage
        }
    }
}

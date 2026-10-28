import Foundation

public struct LinkMetadata: Equatable {
    public var title: String?
    public var summary: String?
    public var siteName: String?
    public var imageURL: URL?
    public var faviconURL: URL?

    public init(
        title: String? = nil,
        summary: String? = nil,
        siteName: String? = nil,
        imageURL: URL? = nil,
        faviconURL: URL? = nil
    ) {
        self.title = title
        self.summary = summary
        self.siteName = siteName
        self.imageURL = imageURL
        self.faviconURL = faviconURL
    }
}

public struct MetadataScraper {
    public static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(from url: URL) async throws -> LinkMetadata {
        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<400).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let limit = 2 * 1024 * 1024
        let html = String(decoding: data.prefix(limit), as: UTF8.self)
        return Self.parse(html: html, baseURL: url)
    }

    public static func parse(html: String, baseURL: URL) -> LinkMetadata {
        let metaAttributes = attributes(inTagsOf: "meta", html: html)
        var meta: [String: String] = [:]
        for attributes in metaAttributes {
            let key = (attributes["property"] ?? attributes["name"] ?? "").lowercased()
            if !key.isEmpty, let content = attributes["content"], !content.isEmpty {
                meta[key] = content
            }
        }

        let title = decoded(meta["og:title"]) ?? decoded(meta["twitter:title"]) ?? pageTitle(in: html)
        let summary = decoded(meta["og:description"]) ?? decoded(meta["twitter:description"]) ?? decoded(meta["description"])
        let siteName = decoded(meta["og:site_name"]) ?? decoded(meta["application-name"])
        let image = resolvedURL(decoded(meta["og:image"]) ?? decoded(meta["og:image:url"]) ?? decoded(meta["twitter:image"]), baseURL: baseURL)
        let favicon = linkHref(relContains: "icon", html: html).flatMap { resolvedURL($0, baseURL: baseURL) }
            ?? resolvedURL("/favicon.ico", baseURL: baseURL)

        return LinkMetadata(
            title: title,
            summary: summary,
            siteName: siteName,
            imageURL: image,
            faviconURL: favicon
        )
    }

    private static func attributes(inTagsOf tag: String, html: String) -> [[String: String]] {
        matches("<\(tag)\\b[^>]*>", in: html).compactMap { match in
            guard let entire = match.first else { return nil }
            return attributes(in: entire)
        }
    }

    private static func attributes(in tagString: String) -> [String: String] {
        var result: [String: String] = [:]
        for match in matches("([A-Za-z_:][-A-Za-z0-9_:.]*)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')", in: tagString) {
            guard match.count >= 4 else { continue }
            let name = match[1].lowercased()
            let value = match[2].isEmpty ? match[3] : match[2]
            if !name.isEmpty { result[name] = value }
        }
        return result
    }

    private static func linkHref(relContains needle: String, html: String) -> String? {
        for tag in matches("<link\\b[^>]*>", in: html) {
            guard let entire = tag.first else { continue }
            let attrs = attributes(in: entire)
            let rel = (attrs["rel"] ?? "").lowercased()
            if rel.contains(needle), let href = attrs["href"] {
                return href
            }
        }
        return nil
    }

    private static func pageTitle(in html: String) -> String? {
        guard let match = matches("<title[^>]*>([\\s\\S]*?)</title>", in: html, dotMatches: true).first,
              match.count >= 2
        else { return nil }
        let title = decoded(match[1])
        return (title?.isEmpty ?? true) ? nil : title
    }

    private static func resolvedURL(_ string: String?, baseURL: URL) -> URL? {
        guard let string, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return URL(string: string, relativeTo: baseURL)?.absoluteURL
    }

    private static func decoded(_ string: String?) -> String? {
        guard let string else { return nil }
        var output = string
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
        output = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return output.isEmpty ? nil : output
    }

    private static func matches(_ pattern: String, in text: String, dotMatches: Bool = false) -> [[String]] {
        var options: NSRegularExpression.Options = [.caseInsensitive]
        if dotMatches { options.insert(.dotMatchesLineSeparators) }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).map { result in
            (0..<result.numberOfRanges).map { index in
                guard let range = Range(result.range(at: index), in: text) else { return "" }
                return String(text[range])
            }
        }
    }
}

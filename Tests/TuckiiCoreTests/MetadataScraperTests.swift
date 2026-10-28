import XCTest
@testable import TuckiiCore

final class MetadataScraperTests: XCTestCase {
    private let baseURL = URL(string: "https://social.example/reel/quick-dinner")!

    func testParsesOpenGraphTags() {
        let html = """
        <html><head>
        <title>Fallback title</title>
        <meta property="og:title" content="Quick dinner recipe &amp; more">
        <meta property="og:description" content="5 vegetables, 1 pan, 15 minutes.">
        <meta property="og:site_name" content="social.example">
        <meta property="og:image" content="/img/quick-dinner.jpg">
        <link rel="apple-touch-icon" href="https://cdn.example/icon.png">
        </head><body></body></html>
        """

        let metadata = MetadataScraper.parse(html: html, baseURL: baseURL)
        XCTAssertEqual(metadata.title, "Quick dinner recipe & more")
        XCTAssertEqual(metadata.summary, "5 vegetables, 1 pan, 15 minutes.")
        XCTAssertEqual(metadata.siteName, "social.example")
        XCTAssertEqual(metadata.imageURL?.absoluteString, "https://social.example/img/quick-dinner.jpg")
        XCTAssertEqual(metadata.faviconURL?.absoluteString, "https://cdn.example/icon.png")
    }

    func testFallsBackToPageTitleAndFavicon() {
        let html = """
        <html><head><title>  Plain page  </title></head><body></body></html>
        """
        let metadata = MetadataScraper.parse(html: html, baseURL: baseURL)
        XCTAssertEqual(metadata.title, "Plain page")
        XCTAssertNil(metadata.summary)
        XCTAssertEqual(metadata.faviconURL?.absoluteString, "https://social.example/favicon.ico")
    }

    func testHandlesNameAttributesAndReversedOrder() {
        let html = """
        <meta content="Named description" name="description">
        <meta content="twitter card title" name="twitter:title">
        """
        let metadata = MetadataScraper.parse(html: html, baseURL: baseURL)
        XCTAssertEqual(metadata.title, "twitter card title")
        XCTAssertEqual(metadata.summary, "Named description")
    }

    func testEmptyHTMLYieldsNoMetadata() {
        let metadata = MetadataScraper.parse(html: "", baseURL: baseURL)
        XCTAssertNil(metadata.title)
        XCTAssertEqual(metadata.faviconURL?.absoluteString, "https://social.example/favicon.ico")
    }
}

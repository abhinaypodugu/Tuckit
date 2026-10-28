import XCTest
@testable import TuckiiCore

final class AppInfoTests: XCTestCase {
    func testDisplayName() {
        XCTAssertEqual(AppInfo.displayName, "Tuckii")
    }
}

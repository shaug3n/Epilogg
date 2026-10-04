import XCTest
@testable import EpiLogg

final class AppLinksTests: XCTestCase {
    func testPublicLinksUseApprovedSecureURLs() {
        XCTAssertEqual(AppLinks.privacyPolicy.absoluteString, "https://epilogg.haugentech.no/personvern")
        XCTAssertEqual(AppLinks.support.absoluteString, "https://epilogg.haugentech.no/support")
        XCTAssertEqual(AppLinks.supportEmail, "epilogg@haugentech.no")
        XCTAssertEqual(AppLinks.privacyPolicy.scheme, "https")
        XCTAssertEqual(AppLinks.support.scheme, "https")
    }
}

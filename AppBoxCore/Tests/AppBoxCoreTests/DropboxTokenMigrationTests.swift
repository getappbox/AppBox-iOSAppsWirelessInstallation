import XCTest
@testable import AppBoxCore

/// Verifies the v3→v4 token migration decodes the legacy `NSKeyedArchiver` `DBAccessToken` archive.
final class DropboxTokenMigrationTests: XCTestCase {

    /// Archives a `LegacyDBAccessToken` under the class name `DBAccessToken`, as the old SDK did.
    private func legacyArchive(uid: String, accessToken: String,
                               refreshToken: String?, expiry: Double) -> Data {
        let token = LegacyDBAccessToken(uid: uid, accessToken: accessToken,
                                        refreshToken: refreshToken, tokenExpirationTimestamp: expiry)
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.setClassName("DBAccessToken", for: LegacyDBAccessToken.self)
        archiver.encode(token, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        return archiver.encodedData
    }

    func testDecodesShortLivedLegacyToken() {
        let data = legacyArchive(uid: "245493250", accessToken: "sl.abc",
                                 refreshToken: "rt.xyz", expiry: 1_700_000_000)
        let decoded = LegacyDBAccessToken.decode(from: data)
        XCTAssertEqual(decoded?.uid, "245493250")
        XCTAssertEqual(decoded?.accessToken, "sl.abc")
        XCTAssertEqual(decoded?.refreshToken, "rt.xyz")
        XCTAssertEqual(decoded?.tokenExpirationTimestamp, 1_700_000_000)

        let token = DropboxTokenMigration.makeToken(from: decoded!)
        XCTAssertEqual(token.accessToken, "sl.abc")
        XCTAssertEqual(token.uid, "245493250")
        XCTAssertEqual(token.refreshToken, "rt.xyz")
        XCTAssertEqual(token.tokenExpirationTimestamp, 1_700_000_000)
    }

    func testDecodesLongLivedLegacyToken() {
        let data = legacyArchive(uid: "42", accessToken: "longlived", refreshToken: nil, expiry: 0)
        let decoded = LegacyDBAccessToken.decode(from: data)
        XCTAssertEqual(decoded?.accessToken, "longlived")
        XCTAssertNil(decoded?.refreshToken)

        let token = DropboxTokenMigration.makeToken(from: decoded!)
        XCTAssertNil(token.refreshToken)
        XCTAssertNil(token.tokenExpirationTimestamp)
    }

    func testConvertedTokenRoundTripsThroughSwiftyDropboxJSON() {
        struct Mirror: Codable, Equatable {
            let accessToken: String; let uid: String
            let refreshToken: String?; let tokenExpirationTimestamp: Double?
        }
        let decoded = LegacyDBAccessToken.decode(
            from: legacyArchive(uid: "7", accessToken: "a", refreshToken: "r", expiry: 123))!
        let token = DropboxTokenMigration.makeToken(from: decoded)
        let json = try! JSONEncoder().encode(token)
        let back = try! JSONDecoder().decode(Mirror.self, from: json)
        XCTAssertEqual(back, Mirror(accessToken: "a", uid: "7", refreshToken: "r", tokenExpirationTimestamp: 123))
    }

    func testDecodeRejectsNonArchiveData() {
        let json = Data(#"{"accessToken":"a","uid":"1"}"#.utf8)
        XCTAssertNil(LegacyDBAccessToken.decode(from: json))
    }
}

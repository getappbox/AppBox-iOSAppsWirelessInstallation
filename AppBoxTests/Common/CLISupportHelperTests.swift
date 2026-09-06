import XCTest
@testable import AppBox

/// The escaping that stands between a bundle path and a root shell. The symlink itself targets a fixed
/// `/usr/local/bin` path, so only the quoting is unit-testable here.
final class CLISupportHelperTests: XCTestCase {

    // MARK: - Shell quoting

    func testWrapsPlainPathsInSingleQuotes() {
        XCTAssertEqual(CLISupportHelper.shellQuoted("/usr/local/bin"), "'/usr/local/bin'")
    }

    func testQuotesPathsContainingSpaces() {
        XCTAssertEqual(CLISupportHelper.shellQuoted("/Applications/App Box.app/Contents"),
                       "'/Applications/App Box.app/Contents'")
    }

    func testClosesAndReopensAroundEmbeddedSingleQuotes() {
        // The POSIX idiom: end the quote, emit an escaped quote, reopen.
        XCTAssertEqual(CLISupportHelper.shellQuoted("/Users/o'brien/app"), "'/Users/o'\\''brien/app'")
    }

    func testNeutralisesShellMetacharacters() {
        for hostile in ["/tmp/a;rm -rf /", "/tmp/$(whoami)", "/tmp/`id`", "/tmp/a&&b", "/tmp/a|b"] {
            let quoted = CLISupportHelper.shellQuoted(hostile)
            XCTAssertTrue(quoted.hasPrefix("'") && quoted.hasSuffix("'"), quoted)
            // Single quotes are literal in POSIX sh, so the payload survives intact rather than executing.
            XCTAssertTrue(quoted.contains(hostile), quoted)
        }
    }

    func testQuotesEmptyStrings() {
        XCTAssertEqual(CLISupportHelper.shellQuoted(""), "''")
    }

    // MARK: - AppleScript escaping

    func testEscapesDoubleQuotes() {
        XCTAssertEqual(CLISupportHelper.appleScriptEscaped("say \"hi\""), "say \\\"hi\\\"")
    }

    func testEscapesBackslashesBeforeQuotes() {
        // Backslashes must be doubled first, or the escape added for a quote would itself be escaped.
        XCTAssertEqual(CLISupportHelper.appleScriptEscaped("a\\b"), "a\\\\b")
        XCTAssertEqual(CLISupportHelper.appleScriptEscaped("a\\\"b"), "a\\\\\\\"b")
    }

    func testLeavesOrdinaryTextAlone() {
        XCTAssertEqual(CLISupportHelper.appleScriptEscaped("/bin/ln -sfn /a /b"), "/bin/ln -sfn /a /b")
    }

    /// A path with both quote kinds must survive shell quoting, then AppleScript escaping on top.
    /// AppleScript doubles the backslash the shell idiom introduced, and unescapes it again before
    /// `do shell script` runs — so the shell still receives `'\''`.
    func testQuotingComposesWithAppleScriptEscaping() {
        let raw = "/Users/o'brien/a\"b"

        let quoted = CLISupportHelper.shellQuoted(raw)
        XCTAssertEqual(quoted, "'/Users/o'\\''brien/a\"b'")

        let escaped = CLISupportHelper.appleScriptEscaped(quoted)
        XCTAssertEqual(escaped, "'/Users/o'\\\\''brien/a\\\"b'")
    }
}

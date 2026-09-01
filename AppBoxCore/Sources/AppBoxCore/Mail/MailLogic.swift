import Foundation

// MARK: - Email validation

public enum EmailValidator {

    private static let singleEmailPattern =
        #"^[A-Z0-9a-z\._%+-]+@([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$"#
    private static let allEmailsPattern =
        #"(([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,}|[0-9]{1,3})(\]?)(\s*,\s*|\s*$))*"#

    /// True if `string` is a single valid email address.
    public static func isValidEmail(_ string: String) -> Bool {
        matches(string, pattern: singleEmailPattern)
    }

    /// True if `string` is a comma-separated list of valid email addresses.
    public static func isAllValidEmails(_ string: String) -> Bool {
        matches(string, pattern: allEmailsPattern)
    }

    private static func matches(_ string: String, pattern: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: string)
    }
}

// MARK: - Notification text

/// Builds the Slack/Teams notification text, which is entirely generated from the build.
public enum BuildNotificationMessage {
    public static func text(name: String, version: String, build: String, installURL: String) -> String {
        "\(name) \(version) (\(build)) is ready to test. Install - \(installURL)"
    }
}

/// Thin surface used by the app's `MailHandler` shim.
public final class ABMailBridge: NSObject {
    public static func isValidEmail(_ string: String) -> Bool {
        EmailValidator.isValidEmail(string)
    }

    public static func isAllValidEmails(_ string: String) -> Bool {
        EmailValidator.isAllValidEmails(string)
    }
}

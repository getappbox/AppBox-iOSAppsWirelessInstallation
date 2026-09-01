import Foundation

/// Validation for user-supplied incoming-webhook URLs; https-only, matching the S5 hardening.
public enum WebhookURL {
    public static func isValid(_ urlString: String?) -> Bool {
        guard let urlString, !urlString.isEmpty,
              let url = URL(string: urlString),
              url.host != nil,
              url.scheme == "https" else { return false }
        return true
    }
}

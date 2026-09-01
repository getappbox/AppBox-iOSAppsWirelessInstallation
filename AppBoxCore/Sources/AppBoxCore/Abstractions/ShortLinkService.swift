import Foundation

/// Shortens an app's long shareable (`appinfo.json`) URL into the public `appbox.me/xxxx` link.
public protocol ShortLinkService: AnyObject {
    /// Return a short URL for the request's `longURL`, or `nil` to fall back to the long URL (a shortener failure leaves the long link in place — uploads still succeed offline).
    func shortLink(for request: ShortLinkRequest) async -> URL?
}

/// What the short-link backend needs to mint a link: the app's identity plus the long URL.
public struct ShortLinkRequest: Equatable, Sendable {
    public var name: String
    public var version: String
    public var build: String
    public var identifier: String
    public var longURL: URL

    public init(name: String, version: String, build: String, identifier: String, longURL: URL) {
        self.name = name
        self.version = version
        self.build = build
        self.identifier = identifier
        self.longURL = longURL
    }
}

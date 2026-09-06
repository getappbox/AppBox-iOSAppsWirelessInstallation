import Foundation

/// Production `DateProvider` returning the real current time.
public final class SystemDateProvider: DateProvider {
    public init() {}
    public func now() -> Date { Date() }
}

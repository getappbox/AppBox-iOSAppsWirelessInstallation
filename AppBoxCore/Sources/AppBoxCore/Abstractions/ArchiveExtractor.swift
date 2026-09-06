import Foundation

/// Abstraction over unzipping an archive (production: ZIPFoundation).
public protocol ArchiveExtractor: AnyObject {
    /// Extracts the zip at `archiveURL` into `destinationURL`, creating the destination if needed.
    func extract(archiveAt archiveURL: URL, to destinationURL: URL) throws

    /// Lists the entry paths inside the zip (without extracting) — used to locate the payload before unzipping.
    func entries(ofArchiveAt archiveURL: URL) throws -> [String]
}

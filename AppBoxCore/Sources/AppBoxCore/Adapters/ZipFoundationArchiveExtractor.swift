import Foundation
import ZIPFoundation

/// Production `ArchiveExtractor` backed by ZIPFoundation.
public final class ZipFoundationArchiveExtractor: ArchiveExtractor {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func extract(archiveAt archiveURL: URL, to destinationURL: URL) throws {
        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        }
        try fileManager.unzipItem(at: archiveURL, to: destinationURL)
    }

    public func entries(ofArchiveAt archiveURL: URL) throws -> [String] {
        let archive = try Archive(url: archiveURL, accessMode: .read)
        return archive.map { $0.path }
    }
}

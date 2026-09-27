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

    public func contents(ofEntry path: String, inArchiveAt archiveURL: URL) throws -> Data {
        let archive = try Archive(url: archiveURL, accessMode: .read)
        guard let entry = archive[path] else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: path])
        }
        var data = Data()
        let checksum = try archive.extract(entry) { data.append($0) }
        guard checksum == entry.checksum else { throw Archive.ArchiveError.invalidCRC32 }
        return data
    }
}

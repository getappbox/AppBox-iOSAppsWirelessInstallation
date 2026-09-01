//
//  StorageErrorText.swift
//  AppBoxCore
//

import Foundation

/// Terminal-facing text for a failed storage operation. The GUI phrases these differently (see `DBErrorHandler`), so the two mappings stay separate on purpose.
public enum StorageErrorText {

    public static func cliMessage(for error: Error) -> String {
        guard let storage = error as? StorageError else {
            return (error as NSError).localizedDescription
        }
        switch storage {
        case .notAuthenticated:
            return "Not logged in to Dropbox. Run `appboxcli login` first."
        case .authenticationFailed(let message), .network(let message),
             .conflict(let message), .server(let message), .unknown(let message):
            return message
        case .notFound:
            return "Not found."
        case .rateLimited:
            return "Dropbox is rate-limiting requests. Please try again shortly."
        case .cancelled:
            return "Cancelled."
        }
    }
}

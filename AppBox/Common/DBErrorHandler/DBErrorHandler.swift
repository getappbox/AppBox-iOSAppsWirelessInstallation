//
//  DBErrorHandler.swift
//  AppBox

import Foundation
import AppBoxCore

public enum DBErrorHandler {

    public static func handleStorageError(_ error: Error, fallbackMessage: String?) {
        let (detail, isAuth) = payload(for: error)
        let fallback = fallbackMessage ?? ""
        let message: String
        if !fallback.isEmpty, !detail.isEmpty {
            message = "\(fallback)\n\n\(detail)"
        } else if !fallback.isEmpty {
            message = fallback
        } else if !detail.isEmpty {
            message = detail
        } else {
            message = "Something goes wrong. Please try again."
        }

        _ = Common.showAlert(withTitle: "Error", andMessage: message)

        if isAuth {
            NotificationCenter.default.post(name: Notification.Name("DropBoxLoggedOutNotification"), object: self)
        }
    }

    /// User-facing message + whether re-login is needed, for a failed storage operation.
    static func payload(for error: Error) -> (message: String, isAuth: Bool) {
        guard let storage = error as? StorageError else {
            return ((error as NSError).localizedDescription, false)
        }
        switch storage {
        case .notAuthenticated, .authenticationFailed:
            return ("You're not signed in to Dropbox. Please log in again.", true)
        case .network:
            return ("No internet connection. Please check your connection and try again.", false)
        case .server, .rateLimited:
            return ("Dropbox had a temporary problem. Please try again.", false)
        case .conflict(let message):
            let detail = message.isEmpty
                ? "The app's install page was changed by another AppBox while this operation was running."
                : message
            return ("\(detail)\n\nNothing was overwritten — please try again.", false)
        case .notFound, .cancelled, .unknown:
            return ("Upload failed: \(storage)", false)
        }
    }
}

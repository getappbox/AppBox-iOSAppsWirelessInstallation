//
//  DropboxAuthCommands.swift
//  AppBoxCLI
//
//  Copyright © 2026 Developer Insider.

import Foundation
import ArgumentParser
import AppBoxCore

/// The Dropbox app key — a public OAuth client_id (PKCE protects the flow without a secret).
enum DropboxAppKey {
    static func value() -> String {
        AppBoxSecrets.dropboxAppKey
    }
}

struct Login: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "login",
        abstract: "Log in to Dropbox (opens your browser to authorize AppBox).")

    func run() async throws {
        let auth = DropboxCLIAuth(appKey: DropboxAppKey.value())
        if auth.isAuthorized {
            print("Already logged in to Dropbox.")
            return
        }

        let request = auth.beginAuthorization()
        print("Opening your browser to authorize AppBox with Dropbox…")
        openInBrowser(request.authorizeURL)
        print("If it doesn't open automatically, visit:\n\(request.authorizeURL.absoluteString)\n")
        print("After approving, Dropbox shows an access code. Paste it here and press Return:")

        guard let code = readLine(strippingNewline: true)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !code.isEmpty else {
            print("No authorization code entered. Aborted.")
            throw ExitCode.failure
        }

        try await auth.completeLogin(request, code: code)
        print("\u{2713} Logged in to Dropbox.")
    }

    private func openInBrowser(_ url: URL) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [url.absoluteString]
        try? task.run()
    }
}

struct Logout: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Log out of Dropbox on this machine (also signs out the AppBox app — they share one session).")

    @Flag(name: .customLong("force"), help: "Skip the confirmation prompt.")
    var force = false

    func run() throws {
        if !force {
            print("This also logs the AppBox app out of Dropbox (they share one session). Continue? [y/N]: ", terminator: "")
            fflush(stdout)
            guard let confirm = readLine(strippingNewline: true)?.lowercased(), confirm == "y" || confirm == "yes" else {
                print("Cancelled.")
                return
            }
        }
        DropboxCLIAuth(appKey: DropboxAppKey.value()).signOut()
        print("\u{2713} Logged out of Dropbox.")
    }
}

struct WhoAmI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "whoami",
        abstract: "Show the Dropbox account you're currently logged in as.")

    func run() async throws {
        let session = DropboxCLISession(appKey: DropboxAppKey.value())
        let account: DropboxCLISession.AccountInfo
        do {
            account = try await session.currentAccount()
        } catch {
            print("Error: \(cliMessage(for: error))")
            throw ExitCode.failure
        }

        print("Name:    \(account.displayName)")
        print("Email:   \(account.email)\(account.emailVerified ? "" : " (unverified)")")
        print("Account: \(account.accountType)")
        if let team = account.teamName { print("Team:    \(team)") }
        if let country = account.country { print("Country: \(country)") }
        print("Locale:  \(account.locale)")
        if account.isPaired { print("Paired:  has a linked personal + work account") }
        print("ID:      \(account.accountId)")
    }
}

struct Space: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "space",
        abstract: "Show Dropbox storage usage (used / total / available).")

    func run() async throws {
        let session = DropboxCLISession(appKey: DropboxAppKey.value())
        let usage: DropboxCLISession.SpaceUsage
        do {
            usage = try await session.spaceUsage()
        } catch {
            print("Error: \(cliMessage(for: error))")
            throw ExitCode.failure
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .binary
        func human(_ bytes: UInt64) -> String { formatter.string(fromByteCount: Int64(clamping: bytes)) }

        print("Used:      \(human(usage.usedBytes))")
        if let allocated = usage.allocatedBytes {
            print("Total:     \(human(allocated))")
            if let available = usage.availableBytes {
                let percent = allocated > 0 ? Double(usage.usedBytes) / Double(allocated) * 100 : 0
                print("Available: \(human(available))")
                print(String(format: "Usage:     %.1f%%", percent))
            }
        }
        switch usage.allocation {
        case .individual:
            print("Plan:      Individual")
        case .team(let teamUsed, let teamAllocated, _, _):
            print("Plan:      Team")
            print("Team used: \(human(teamUsed)) of \(human(teamAllocated))")
        case .other:
            break
        }
    }
}

/// Extract a clean, user-facing message from a thrown error for terminal output (so a failed query prints "Error: Not logged in…" rather than a raw enum case).
func cliMessage(for error: Error) -> String {
    StorageErrorText.cliMessage(for: error)
}

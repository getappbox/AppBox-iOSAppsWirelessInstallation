import Foundation
import SwiftyDropbox

/// Authorized Dropbox queries for the CLI: account identity (`whoami`) and storage usage (`space`).
public final class DropboxCLISession {

    /// The signed-in Dropbox account (the bits worth showing in `whoami`).
    public struct AccountInfo: Equatable {
        public let displayName: String
        public let email: String
        public let emailVerified: Bool
        public let accountId: String
        public let accountType: String
        public let country: String?
        public let locale: String
        public let teamName: String?
        public let isPaired: Bool
    }

    /// Dropbox storage usage.
    public struct SpaceUsage: Equatable {
        public enum Allocation: Equatable {
            case individual(allocated: UInt64)
            /// A team account.
            case team(used: UInt64, allocated: UInt64, userAllocated: UInt64, userUsed: UInt64)
            case other
        }

        /// This user's own usage (the API's per-user `used`, not any team-wide total).
        public let usedBytes: UInt64
        public let allocation: Allocation

        /// The total space available to **this user** — the individual allocation, or the member's within-team quota.
        public var allocatedBytes: UInt64? {
            switch allocation {
            case .individual(let allocated): return allocated
            case .team(_, _, let userAllocated, _): return userAllocated > 0 ? userAllocated : nil
            case .other: return nil
            }
        }

        /// Remaining space (allocated − used), clamped at 0, when a personal total is known.
        public var availableBytes: UInt64? {
            guard let allocated = allocatedBytes else { return nil }
            return allocated > usedBytes ? allocated - usedBytes : 0
        }
    }

    private let appKey: String
    private let secureStorage: SecureStorageAccess

    /// `secureStorage` defaults to the same CLI-safe Keychain store `DropboxCLIAuth` writes to, so the token stored at login is the one these queries read.
    public init(appKey: String,
                secureStorage: SecureStorageAccess = CLISecureStorageAccess(service: "com.developerinsider.AppBox.dropbox.authv2")) {
        self.appKey = appKey
        self.secureStorage = secureStorage
    }

    /// Fetch the current account (`users/get_current_account`).
    public func currentAccount() async throws -> AccountInfo {
        let client = try authorizedClient()
        switch await client.users.getCurrentAccount().responseResult() {
        case .success(let account):
            return AccountInfo(
                displayName: account.name.displayName,
                email: account.email,
                emailVerified: account.emailVerified,
                accountId: account.accountId,
                accountType: DropboxCLISession.describe(account.accountType),
                country: account.country,
                locale: account.locale,
                teamName: account.team?.name,
                isPaired: account.isPaired
            )
        case .failure(let error):
            throw DropboxStorageProvider.map(error)
        }
    }

    /// Fetch storage usage (`users/get_space_usage`).
    public func spaceUsage() async throws -> SpaceUsage {
        let client = try authorizedClient()
        switch await client.users.getSpaceUsage().responseResult() {
        case .success(let usage):
            let allocation: SpaceUsage.Allocation
            switch usage.allocation {
            case .individual(let individual):
                allocation = .individual(allocated: individual.allocated)
            case .team(let team):
                allocation = .team(used: team.used, allocated: team.allocated,
                                   userAllocated: team.userWithinTeamSpaceAllocated,
                                   userUsed: team.userWithinTeamSpaceUsedCached)
            case .other:
                allocation = .other
            }
            return SpaceUsage(usedBytes: usage.used, allocation: allocation)
        case .failure(let error):
            throw DropboxStorageProvider.map(error)
        }
    }

    // MARK: - Client setup

    private func authorizedClient() throws -> DropboxClient {
        CLIDropboxClient.ensureConfigured(appKey: appKey, secureStorage: secureStorage)
        guard let client = DropboxClientsManager.authorizedClient else {
            throw StorageError.authenticationFailed("Not logged in to Dropbox. Run `appboxcli login` first.")
        }
        return client
    }

    private static func describe(_ type: UsersCommon.AccountType) -> String {
        switch type {
        case .basic: return "Basic"
        case .pro: return "Pro"
        case .business: return "Business"
        @unknown default: return "Unknown"
        }
    }
}

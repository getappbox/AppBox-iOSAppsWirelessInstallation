//
//  BuildRecordStore.swift
//  AppBoxCore
//

import Foundation
import CoreData

/// The dashboard fields for one completed upload.
public struct BuildRecordInput {
    public var identifier: String
    public var name: String
    public var version: String
    public var build: String
    public var buildType: String?
    public var localIPAPath: String?
    public var keepSameLink: Bool

    public var bundleDirectory: String
    public var buildDirectory: String
    public var ipaRemotePath: String
    public var manifestRemotePath: String
    public var appInfoRemotePath: String

    public var sharedIPAURL: String?
    public var sharedManifestURL: String?
    public var sharedAppInfoURL: String?
    public var shortURL: String?

    public var provisioning: MobileProvisionInfo?
    public var date: Date

    public init(identifier: String, name: String, version: String, build: String,
                buildType: String? = nil, localIPAPath: String? = nil, keepSameLink: Bool = false,
                bundleDirectory: String, buildDirectory: String, ipaRemotePath: String,
                manifestRemotePath: String, appInfoRemotePath: String,
                sharedIPAURL: String? = nil, sharedManifestURL: String? = nil,
                sharedAppInfoURL: String? = nil, shortURL: String? = nil,
                provisioning: MobileProvisionInfo? = nil, date: Date = Date()) {
        self.identifier = identifier
        self.name = name
        self.version = version
        self.build = build
        self.buildType = buildType
        self.localIPAPath = localIPAPath
        self.keepSameLink = keepSameLink
        self.bundleDirectory = bundleDirectory
        self.buildDirectory = buildDirectory
        self.ipaRemotePath = ipaRemotePath
        self.manifestRemotePath = manifestRemotePath
        self.appInfoRemotePath = appInfoRemotePath
        self.sharedIPAURL = sharedIPAURL
        self.sharedManifestURL = sharedManifestURL
        self.sharedAppInfoURL = sharedAppInfoURL
        self.shortURL = shortURL
        self.provisioning = provisioning
        self.date = date
    }
}

extension BuildRecordInput {
    /// Builds the dashboard entry for a finished upload.
    public init(outcome: BuildUploadOutcome, localIPAPath: String?, keepSameLink: Bool, date: Date = Date()) {
        self.init(identifier: outcome.metadata.identifier,
                  name: outcome.metadata.name,
                  version: outcome.metadata.version,
                  build: outcome.metadata.build,
                  buildType: outcome.provisioning?.buildType,
                  localIPAPath: localIPAPath,
                  keepSameLink: keepSameLink,
                  bundleDirectory: outcome.paths.bundleDirectory,
                  buildDirectory: outcome.paths.buildDirectory,
                  ipaRemotePath: "/" + outcome.paths.ipa.components.joined(separator: "/"),
                  manifestRemotePath: "/" + outcome.paths.manifest.components.joined(separator: "/"),
                  appInfoRemotePath: "/" + outcome.paths.appInfo.components.joined(separator: "/"),
                  sharedIPAURL: outcome.result.ipaLink.absoluteString,
                  sharedManifestURL: outcome.result.manifestLink.absoluteString,
                  sharedAppInfoURL: outcome.result.appInfoSharedLink.absoluteString,
                  shortURL: outcome.result.shortLink.absoluteString,
                  provisioning: outcome.provisioning,
                  date: date)
    }
}

/// Writes completed uploads into the shared Core Data store that both the app and the CLI read.
public enum BuildRecordStore {

    /// Finds or creates the project, appends an upload record with its provisioning profile and devices, then saves.
    @discardableResult
    public static func save(_ input: BuildRecordInput,
                            in context: NSManagedObjectContext,
                            save: () throws -> Void) throws -> ABProject {
        let fetch = NSFetchRequest<ABProject>(entityName: "Project")
        fetch.predicate = NSPredicate(format: "SELF.bundleIdentifier = %@", input.identifier)
        let projects = try context.fetch(fetch)

        let project: ABProject
        if let existing = projects.last {
            project = existing
        } else {
            project = NSEntityDescription.insertNewObject(forEntityName: "Project", into: context) as! ABProject
            project.bundleIdentifier = input.identifier
        }
        project.name = input.name

        let record = NSEntityDescription.insertNewObject(forEntityName: "UploadRecord", into: context) as! ABUploadRecord
        record.buildType = input.buildType
        record.dbAppInfoFullPath = input.appInfoRemotePath
        record.dbDirectroy = input.buildDirectory
        record.dbFolderName = input.bundleDirectory
        record.dbIPAFullPath = input.ipaRemotePath
        record.dbManifestFullPath = input.manifestRemotePath
        record.dbSharedIPAURL = input.sharedIPAURL
        record.dbSharedManifestURL = input.sharedManifestURL
        record.dbSharedAppInfoURL = input.sharedAppInfoURL
        record.localBuildPath = input.localIPAPath
        record.shortURL = input.shortURL
        record.build = input.build
        record.version = input.version
        record.keepSameLink = NSNumber(value: input.keepSameLink)
        record.datetime = input.date

        if let provisioning = input.provisioning {
            record.provisioningProfile = profile(for: provisioning, in: context, record: record)
        }

        project.mutableOrderedSetValue(forKey: "uploadRecords").add(record)
        try save()
        return project
    }

    private static func profile(for provisioning: MobileProvisionInfo,
                                in context: NSManagedObjectContext,
                                record: ABUploadRecord) -> ABProvisioningProfile {
        let fetch = NSFetchRequest<ABProvisioningProfile>(entityName: "ProvisioningProfile")
        fetch.predicate = NSPredicate(format: "uuid = %@", provisioning.uuid ?? "")
        let existing = ((try? context.fetch(fetch)) ?? []).first

        let profile: ABProvisioningProfile
        if let existing {
            profile = existing
        } else {
            profile = NSEntityDescription.insertNewObject(forEntityName: "ProvisioningProfile",
                                                          into: context) as! ABProvisioningProfile
            profile.uuid = provisioning.uuid
            profile.teamId = provisioning.teamId
            profile.teamName = provisioning.teamName
            profile.buildType = provisioning.buildType
            profile.createDate = provisioning.createDate
            profile.expirationDate = provisioning.expirationDate

            let devices = NSMutableOrderedSet()
            for deviceId in provisioning.provisionedDevices ?? [] {
                let device = NSEntityDescription.insertNewObject(forEntityName: "ProvisionedDevice",
                                                                 into: context) as! ABProvisionedDevice
                device.deviceId = deviceId
                devices.add(device)
            }
            profile.mutableOrderedSetValue(forKey: "provisionedDevices").union(devices)
        }
        profile.mutableOrderedSetValue(forKey: "uploadRecord").add(record)
        return profile
    }
}

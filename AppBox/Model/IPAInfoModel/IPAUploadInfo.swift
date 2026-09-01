//
//  IPAUploadInfo.swift
//  AppBox

import Foundation
import AppBoxCore

public final class IPAUploadInfo: NSObject {

    // MARK: - Project basic properties

    private var _uuid: String?
    public var uuid: String? {
        get { createUDIDAndIsNew(false); return _uuid }
        set { _uuid = newValue }
    }

    private var _name: String?
    public var name: String? {
        get { _name }
        set { _name = newValue.map { ABIPAInfo.stripSpaces($0) } }
    }

    public var version: String?
    public var build: String?
    public var identifer: String?
    public var buildType: String?
    public var ipaFileSize: NSNumber?
    public var miniOSVersion: String?
    public var supportedDevice: String?

    // MARK: - Local URLs

    private var _ipaFullPath: URL?
    public var ipaFullPath: URL? {
        get { _ipaFullPath }
        set {
            _ipaFullPath = newValue
            if let path = (newValue as NSURL?)?.resourceSpecifier?.removingPercentEncoding,
               let attributes = try? FileManager.default.attributesOfItem(atPath: path),
               let size = (attributes[.size] as? NSNumber)?.int64Value {
                ipaFileSize = NSNumber(value: size / 1_000_000)
            } else {
                ipaFileSize = NSNumber(value: 0)
            }
        }
    }

    // MARK: - Info.plist + provisioning

    private var _ipaInfoPlist: [AnyHashable: Any]?
    public var ipaInfoPlist: [AnyHashable: Any]? {
        get { _ipaInfoPlist }
        set {
            _ipaInfoPlist = newValue
            createUDIDAndIsNew(true)
            if let bundleName = newValue?["CFBundleName"] as? String { name = bundleName }
            build = newValue?["CFBundleVersion"] as? String
            identifer = newValue?["CFBundleIdentifier"] as? String
            version = newValue?["CFBundleShortVersionString"] as? String
            miniOSVersion = newValue?["MinimumOSVersion"] as? String
            supportedDevice = ABIPAInfo.supportedDevice(fromDeviceFamily: newValue?["UIDeviceFamily"] as? [NSNumber])

            let bundlePath = "/\(identifer ?? "")"
            if (bundleDirectory?.absoluteString ?? "").isEmpty {
                bundleDirectory = URL(string: bundlePath)
            }
            upadteDbDirectoryByBundleDirectory()
        }
    }

    private var _mobileProvision: MobileProvision?
    public var mobileProvision: MobileProvision? {
        get { _mobileProvision }
        set {
            _mobileProvision = newValue
            if let provision = newValue, buildType == nil { buildType = provision.buildType }
        }
    }

    // MARK: - UniqueLink.json

    public var isKeepSameLinkEnabled: Bool = false
    public var uniquelinkShareableURL: URL?

    // MARK: - Share settings

    public var emails: String?
    public var keepSameLink: NSNumber?
    public var personalMessage: String?
    public var slackWebhook: String?
    public var msTeamsWebhook: String?

    // MARK: - Shareable URLs (Dropbox / shortened)

    public var dbDirectory: URL?
    public var dbIPAFullPath: URL?
    public var dbManifestFullPath: URL?
    public var dbAppInfoJSONFullPath: URL?
    public var bundleDirectory: URL?
    public var ipaFileDBShareableURL: URL?
    public var manifestFileSharableURL: URL?
    public var appLongShareableURL: URL?
    public var appShortShareableURL: URL?

    // MARK: - Init

    public override init() {
        super.init()
        keepSameLink = NSNumber(value: 0)
        emails = ""
        buildType = ""
        personalMessage = ""
    }

    // MARK: - Helpers

    public func createUDIDAndIsNew(_ isNew: Bool) {
        if isNew || _uuid == nil {
            _uuid = Common.generateUUID()
        }
    }

    public func isValidInfoPlist() -> Bool {
        guard ipaInfoPlist != nil else { return false }
        return name != nil && build != nil && identifer != nil && version != nil
    }

    public func upadteDbDirectoryByBundleDirectory() {
        let metadata = BuildMetadata(name: name ?? "", version: version ?? "", build: build ?? "",
                                     identifier: identifer ?? "", minimumOSVersion: miniOSVersion,
                                     supportedDevice: supportedDevice ?? "")
        let paths = BuildRemotePaths(metadata: metadata, uuid: uuid ?? "",
                                     bundleDirectory: bundleDirectory?.absoluteString,
                                     keepSameLink: isKeepSameLinkEnabled)
        dbDirectory = URL(string: paths.buildDirectory)
        dbIPAFullPath = URL(string: paths.ipa.path)
        dbManifestFullPath = URL(string: paths.manifest.path)
        dbAppInfoJSONFullPath = URL(string: paths.appInfo.path)
    }

    public func validURLString(_ urlString: String?) -> String {
        return ABIPAInfo.sanitizedURLString(urlString)
    }
}

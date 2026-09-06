//
//  HelpPreferencesViewController.swift
//  AppBox

import AppKit

public final class HelpPreferencesViewController: NSViewController {

    public override func loadView() {
        view = HelpPreferencesHost.makeView(
            documentationURL: "https://docs.getappbox.com",
            cliURL: "https://docs.getappbox.com/CommandLineInterface/",
            releasesURL: "https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation/releases/latest",
            licenseURL: "https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation/blob/master/LICENSE.md")
    }
}

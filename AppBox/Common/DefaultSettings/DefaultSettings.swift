//
//  DefaultSettings.swift
//  AppBox

import Foundation

public final class DefaultSettings: NSObject {

    public class func setFirstTimeSettings() {
        if UserData.isFirstTime() {
            UserData.setIsFirstTime(true)
            UserData.setDownloadIPAEnable(false)
            UserData.setMoreDetailsEnable(true)
            UserData.setShowPreviousVersions(true)
        }

        UserData.recordLaunchedVersion()
    }

    public class func setEveryStartupSettings() {
    }
}

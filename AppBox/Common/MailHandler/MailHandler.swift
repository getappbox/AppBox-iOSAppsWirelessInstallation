//
//  MailHandler.swift
//  AppBox

import Foundation
import AppBoxCore

public final class MailHandler: NSObject {

    public class func isValidEmail(_ checkString: String?) -> Bool {
        ABMailBridge.isValidEmail(checkString ?? "")
    }

    public class func isAllValidEmail(_ checkString: String?) -> Bool {
        ABMailBridge.isAllValidEmails(checkString ?? "")
    }

    public class func showInvalidEmailAddressAlert() {
        Common.showAlert(
			withTitle: "Invalid email address",
			andMessage: "The email address entered was invalid. Please reenter it (Example: username@example.com).\n\nFor multiple email please enter like (username@example.com,username2@example.com,username@example2.com).")
    }
}

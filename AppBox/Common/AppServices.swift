//
//  AppServices.swift
//  AppBox

import Foundation
import AppBoxCore

enum AppServices {
    static let serviceClient = AppBoxServiceClient(
        configuration: .production(clientToken: AppBoxSecrets.clientToken),
        httpClient: URLSessionHTTPClient(),
        tokenProvider: DropboxSessionTokenProvider())

    static let appKeyProvider = DropboxAppKeyProvider(
		store: UserDefaultsKeyValueStore(),
		fallback: AppBoxSecrets.dropboxAppKey)
}

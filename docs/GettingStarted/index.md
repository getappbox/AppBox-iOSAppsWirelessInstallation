---
title: Getting Started
hide:
  - navigation
---

## Installation

AppBox requires macOS 15 Sequoia or later.

### 1. Quick Install
You can install AppBox by running following command in your terminal -
```bash
curl -s https://getappbox.com/install.sh | bash
```

### 2. Using Homebrew
You can install AppBox via Homebrew by running following command in your terminal -
```bash
brew install --cask appbox
```

Update it later with `brew upgrade --cask appbox`.

### 3. Manual Install
If you face any issue using above commands then you can manually install AppBox by downloading [AppBox.dmg](https://getappbox.com/download/). Open the DMG and drag `AppBox.app` into your `Applications` folder.

Every release also attaches `AppBox.dmg` and `AppBox.app.zip` directly, along with `appboxcli.zip` for the standalone command-line tool, see [Releases](https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation/releases/latest).

## How to use AppBox 
1. Open AppBox.
2. Link your Dropbox account to AppBox by signing in with your Dropbox account.
3. Drag and drop your .ipa file into AppBox or select it through the file browser.
4. Click "Upload IPA" button to upload the app and generate install URL.
5. AppBox creates a secure installation link that you can share with your team or testers.
6. Users open the link in Safari on their iOS device and install the app with one tap.
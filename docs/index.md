---
title: Home
hide:
  - navigation
---

AppBox is a tool for developers to build and deploy Development and In-house applications directly to the devices from your Dropbox account.

## Why AppBox?
#### 1. Unlimited App Installations     
Deploy as many apps as you need without any restrictions. Scale your development and testing workflow without worrying about installation limits.
#### 2. No File Size Restrictions
Upload apps of any size without limitations. Whether it's a lightweight utility or a resource-heavy game, AppBox handles it all seamlessly.
#### 3. Never Expire
Your uploaded apps remain accessible indefinitely. No more worrying about broken links or expired installations disrupting your workflow.
#### 4. Persistent Installation Links
Each app gets a unique, permanent installation link that remains consistent across updates. Share once, use forever with automatic version management.
#### 5. Version History Access
Install any previous version of your app using the same link. Perfect for testing regressions, comparing versions, or rolling back when needed.
#### 6. Email Distribution
Automatically send installation links via email to your team members and beta testers. Streamline your app distribution workflow with built-in notifications.
#### 7. Smart Upload Recovery
Automatically resume uploads after network interruptions or failures. Never lose progress on large file uploads due to connectivity issues.
#### 8. Team Chat Integration
Connect with Slack, Microsoft Teams, and Google Chat through webhooks. Get instant notifications when new builds are ready for testing.
#### 9. Centralized Dashboard
Manage all your uploaded apps from a single, intuitive dashboard. Access and manage all your uploaded builds from this interface.
#### 10. Fastlane Integration
Seamlessly integrate with your existing Fastlane workflows. Automate app uploads and distribution as part of your CI/CD pipeline.

## Installation

#### 1. Using curl
You can install AppBox by running following command in your terminal -
```bash
curl -s https://getappbox.com/install.sh | bash
```
#### 2. Manual Install
If you face any issue using above command then you can manually install AppBox by downloading it from [here](https://getappbox.com/download/). After that, unzip `AppBox.app.zip` and move `AppBox.app` into `/Applications` directory.

## How to use AppBox 
1. Open AppBox.
2. Link your Dropbox account to AppBox by signing in with your Dropbox account.
3. Drag and drop your .ipa file into AppBox or select it through the file browser.
4. Click "Upload IPA" button to upload the app and generate install URL.
5. AppBox creates a secure installation link that you can share with your team or testers.
6. Users open the link in Safari on their iOS device and install the app with one tap.
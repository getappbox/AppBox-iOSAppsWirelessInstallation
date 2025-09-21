---
title: Command Line Interface
hide:
  - navigation
---

# AppBox Command Line Interface (CLI)

AppBox provides a powerful command-line interface that allows you to automate your iOS app deployment workflow. The CLI tool integrates seamlessly with your existing development process and CI/CD pipelines.

## Prerequisites

Before installing/using the AppBox CLI tool, ensure that:
1. The AppBox application must be installed in `/Applications/AppBox.app`
2. You must have linked your Dropbox account with AppBox

## Installation
The AppBox CLI tool can be installed directly from the AppBox application using the built-in installation manager.

1. Open the AppBox application
2. Click on CLI menu options
3. Click "Install CLI Tool"
    ![](Screenshots/ABCLIMenu.webp)
4. System will prompt for authentication. Enter your system password to proceed.
    ![](Screenshots/ABCLIInstallUninstallPassword.webp)
5. AppBox will install the CLI tool and display a success message once the installation is complete.
    ![](Screenshots/ABCLIInstallSuccess.webp)
6. After installation, you can verify that the CLI tool is properly installed by running:

    ```bash
    appboxcli -h
    ```
    ![](Screenshots/ABCLIHelp.webp)

The installation process will:
- Create a symbolic link to the CLI tool in `/usr/local/bin/`
- Make the `appboxcli` command available system-wide
- Configure proper permissions for command execution

This authentication is required because the CLI tool installation process needs administrative privileges to:
- Create symbolic links in system directories
- Set appropriate file permissions
- Configure the CLI environment

### Uninstallation

To uninstall the CLI tool, AppBox provides an easy uninstallation process:

1. Open AppBox application
2. Click on CLI menu options
3. Click "Uninstall CLI Tool"
4. Confirm the uninstallation when prompted
    ![](Screenshots/ABCLIUninstallConfirm.webp)
5. The system will remove the CLI tool and display a success message
    ![](Screenshots/ABCLIUninstallSuccessfully.webp)


## Command Reference

The AppBox CLI tool provides comprehensive options for uploading and distributing your iOS applications.

### Basic Syntax

```bash
appboxcli --ipa <path-to-ipa-file> [options]
```

### Required Parameters

#### `--ipa <path>`
**Required** - Specifies the path to the IPA file you want to upload.

```bash
appboxcli --ipa /path/to/your/app.ipa
```

### Optional Parameters

#### `--emails <email-list>`
Comma-separated list of email addresses that should receive the application installation link.

```bash
appboxcli --ipa app.ipa --emails "tester1@company.com,tester2@company.com"
```

#### `--message <message>`
Attach a personal message to the distribution email. You can use the following keywords in your message:
- `{BUILD_NAME}` - Application name
- `{BUILD_VERSION}` - Application version
- `{BUILD_NUMBER}` - Build number

```bash
appboxcli --ipa app.ipa --message "New build {BUILD_NAME} v{BUILD_VERSION} is ready for testing!"
```

#### `--keepsamelink`
Keep the same short URL for all future uploads of IPAs with the same bundle identifier. This is useful for maintaining consistent installation links.

```bash
appboxcli --ipa app.ipa --keepsamelink
```

#### `--dbfolder <folder-name>`
Specify a custom Dropbox folder name. By default, the folder name will be the application's bundle identifier. This is used with keepsamelink option.

```bash
appboxcli --ipa app.ipa --keepsamelink --dbfolder "MyCustomFolder"
```

#### `--webhookmessage <message>`
Custom message to send along with Slack or Microsoft Teams notifications. You can use the following keywords in your message:
- `{BUILD_NAME}` - Application name
- `{BUILD_VERSION}` - Application version
- `{BUILD_NUMBER}` - Build number
- `{SHARE_URL}` - Installation link URL

```bash
appboxcli --ipa app.ipa --webhookmessage "🚀 New build available: {SHARE_URL}"
```

#### `--slackwebhook <webhook-url>`
Slack Incoming Webhook URL to send notifications to a Slack channel.

```bash
appboxcli --ipa app.ipa --slackwebhook "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

#### `--msteamswebhook <webhook-url>`
Microsoft Teams Incoming Webhook URL to send notifications to a Teams channel.

```bash
appboxcli --ipa app.ipa --msteamswebhook "https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK"
```

## Usage Examples

### Simple Upload
Upload an IPA file with minimal configuration:

```bash
appboxcli --ipa MyApp.ipa
```

### Upload with Email Distribution
Upload and automatically send installation links to specific email addresses:

```bash
appboxcli --ipa MyApp.ipa \
  --emails "dev-team@company.com,qa-team@company.com" \
  --message "New build {BUILD_NAME} v{BUILD_VERSION} is ready for testing. Please test the new features and report any issues."
```

### Complete CI/CD Example
Full example with all options for a comprehensive CI/CD pipeline:

```bash
appboxcli --ipa builds/MyApp.ipa \
  --emails "beta-testers@company.com" \
  --message "🎉 New beta build {BUILD_NAME} v{BUILD_VERSION} ({BUILD_NUMBER}) is now available!" \
  --keepsamelink \
  --dbfolder "MyApp-Beta" \
  --slackwebhook "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX" \
  --webhookmessage "📱 New iOS build deployed: {BUILD_NAME} v{BUILD_VERSION}\n🔗 Install: {SHARE_URL}"
```

### Team Collaboration Example
Upload with notifications to multiple platforms:

```bash
appboxcli --ipa MyApp.ipa \
  --emails "mobile-team@company.com" \
  --message "Daily build {BUILD_NAME} ready for testing" \
  --slackwebhook "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" \
  --msteamswebhook "https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK" \
  --webhookmessage "Daily build available: {SHARE_URL}"
```

## Error Handling

The CLI tool provides comprehensive error handling and logging:
- **Exit Code 0**: Success
- **Exit Code 111**: Email sending failed
- **Exit Code 118**: Unable to create manifest file
- **Exit Code 119**: IPA file not found
- **Exit Code 120**: Info.plist not found in IPA
- **Exit Code 121**: Unable to unzip IPA file
- **Exit Code 124**: Upload failed
- **Exit Code 127**: Invalid command

## Troubleshooting

### Common Issues

1. **Command Not Found**
   ```bash
   # Verify installation
   which appboxcli
   # Reinstall if necessary through AppBox GUI
   ```

2. **Permission Denied**
   ```bash
   # Check file permissions
   ls -la /usr/local/bin/appboxcli
   # Reinstall CLI tool if permissions are incorrect
   ```

3. **AppBox Not Found Error**
   - Ensure AppBox.app is installed in `/Applications/` folder
   - Verify AppBox is properly configured with Dropbox access

4. **Upload Failures**
   - Check internet connection
   - Verify Dropbox account has sufficient storage
   - Ensure IPA file is valid and not corrupted

### Getting Help

For additional help and support:

- Run `appboxcli --help` for command-line options
- Visit the [AppBox Documentation](https://docs.getappbox.com)
- Report issues on [GitHub](https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation/issues)


The AppBox CLI tool provides a powerful and flexible way to automate your iOS app distribution workflow, making it easy to integrate with any development and deployment process.


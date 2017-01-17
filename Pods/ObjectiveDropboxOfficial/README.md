# Dropbox for Objective-C

The Official Dropbox Objective-C SDK for integrating with Dropbox [API v2](https://www.dropbox.com/developers/documentation/http/documentation) on iOS or macOS.

Full documentation [here](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/).

---

## Table of Contents

* [System requirements](#system-requirements)
  * [Xcode 8 and iOS 10 bug](#xcode-8-and-ios-10-bug)
* [Get started](#get-started)
  * [Register your application](#register-your-application)
  * [Obtain an OAuth 2.0 token](#obtain-an-oauth-20-token)
* [SDK distribution](#sdk-distribution)
  * [CocoaPods](#cocoapods)
  * [Carthage](#carthage)
  * [Manually add subproject](#manually-add-subproject)
* [Configure your project](#configure-your-project)
  * [Application `.plist` file](#application-plist-file)
  * [Handling the authorization flow](#handling-the-authorization-flow)
    * [Initialize a `DropboxClient` instance](#initialize-a-dropboxclient-instance)
    * [Begin the authorization flow](#begin-the-authorization-flow)
    * [Handle redirect back into SDK](#handle-redirect-back-into-sdk)
* [Try some API requests](#try-some-api-requests)
  * [Dropbox client instance](#dropbox-client-instance)
  * [Handle the API response](#handle-the-api-response)
  * [Request types](#request-types)
    * [RPC-style request](#rpc-style-request)
    * [Upload-style request](#upload-style-request)
    * [Download-style request](#download-style-request)
  * [Handling responses and errors](#handling-responses-and-errors)
    * [Route-specific errors](#route-specific-errors)
    * [Generic network request errors](#generic-network-request-errors)
    * [Response handling edge cases](#response-handling-edge-cases)
  * [Customizing network calls](#customizing-network-calls)
    * [Configure network client](#configure-network-client)
    * [Specify API call response queue](#specify-api-call-response-queue)
  * [`DropboxClientsManager` class](#dropboxclientsmanager-class)
    * [Single Dropbox user case](#single-dropbox-user-case)
    * [Multiple Dropbox user case](#multiple-dropbox-user-case)
* [Examples](#examples)
* [Documentation](#documentation)
* [Stone](#stone)
* [Modifications](#modifications)
* [Bugs](#bugs)

---

## System requirements

- iOS 8.0+
- macOS 10.10+
- Xcode 7.3+

---

### Xcode 8 and iOS 10 bug

> The Dropbox Objective-C SDK currently supports Xcode 8 and iOS 10. However, there appears to be a bug with the Keychain in the iOS simulator environment where data is not persistently saved to the Keychain.
>
> As a temporary workaround, in the Project Navigator, select **your project** > **Capabilities** > **Keychain Sharing** > **ON**.
>
> You can read more about the bug [here](https://forums.developer.apple.com/message/170381#170381).

## Get started

### Register your application

Before using this SDK, you should register your application in the [Dropbox App Console](https://dropbox.com/developers/apps). This creates a record of your app with Dropbox that will be associated with the API calls you make.

### Obtain an OAuth 2.0 token

All requests need to be made with an OAuth 2.0 access token. An OAuth token represents an authenticated link between a Dropbox app and
a Dropbox user account or team.

Once you've created an app, you can go to the App Console and manually generate an access token to authorize your app to access your own Dropbox account.
Otherwise, you can obtain an OAuth token programmatically using the SDK's pre-defined auth flow. For more information, [see below](https://github.com/dropbox/dropbox-sdk-obj-c#handling-authorization-flow).

---

## SDK distribution

You can integrate the Dropbox Objective-C SDK into your project using one of several methods.

### CocoaPods

To use [CocoaPods](http://cocoapods.org), a dependency manager for Cocoa projects, you should first install it using the following command:

```bash
$ gem install cocoapods
```

Then navigate to the directory that contains your project and create a new file called `Podfile`. You can do this either with `pod init`, or open an existing Podfile, and then add `pod 'ObjectiveDropboxOfficial'` to the main loop. Your Podfile should look something like this:

```ruby
target '<YOUR_PROJECT_NAME>' do
    pod 'ObjectiveDropboxOfficial'
end
```

Then, run the following command to install the dependency:

```bash
$ pod install
```

Once your project is integrated with the Dropbox Objective-C SDK, you can pull SDK updates using the following command:

```bash
$ pod update
```

---

### Carthage

You can also integrate the Dropbox Objective-C SDK into your project using [Carthage](https://github.com/Carthage/Carthage), a decentralized dependency manager for Cocoa. Carthage offers more flexibility than CocoaPods, but requires some additional work. You can install Carthage (with Xcode 7+) via [Homebrew](http://brew.sh/):

```bash
brew update
brew install carthage
```

 To install the Dropbox Objective-C SDK via Carthage, you need to create a `Cartfile` in your project with the following contents:

```
# ObjectiveDropboxOfficial
github "https://github.com/dropbox/dropbox-sdk-obj-c" ~> 2.0.6
```

Then, run the following command to checkout and build the Dropbox Objective-C SDK repository:

##### iOS

```bash
carthage update --platform iOS
```

In the Project Navigator in Xcode, select your project, and then navigate to **General** > **Linked Frameworks and Libraries**, then drag and drop `ObjectiveDropboxOfficial.framework` (from `Carthage/Build/iOS`).

Then, navigate to **Build Phases** > **+** > **New Run Script Phase**. In the newly-created **Run Script** section, add the following code to the script body area (beneath the "Shell" box):

```
/usr/local/bin/carthage copy-frameworks
```

Then, navigate to the **Input Files** section and add the following path:

```
$(SRCROOT)/Carthage/Build/iOS/ObjectiveDropboxOfficial.framework
```

##### macOS
```bash
carthage update --platform Mac
```

In the Project Navigator in Xcode, select your project, and then navigate to **General** > **Embedded Binaries**, then drag and drop `ObjectiveDropboxOfficial.framework` (from `Carthage/Build/Mac`).

Then navigate to **Build Phases** > **+** > **New Copy Files Phase**. In the newly-created **Copy Files** section, click the **Destination** drop-down menu and select **Products Directory**, then drag and drop `ObjectiveDropboxOfficial.framework.dSYM` (from `Carthage/Build/Mac`).

---

### Manually add subproject

Finally, you can also integrate the Dropbox Objective-C SDK into your project manually with the help of Carthage. Please take the following steps:

Create a `Cartfile` in your project with the same contents as the Cartfile listed in the [Carthage](#carthage) section of the README.

Then, run the following command to checkout and build the Dropbox Objective-C SDK repository:

##### iOS

```bash
carthage update --platform iOS
```
Once you have checked-out out all the necessary code via Carthage, drag the `Carthage/Checkouts/ObjectiveDropboxOfficial/Source/ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.xcodeproj` file into your project as a subproject.

Then, in the Project Navigator in Xcode, select your project, and then navigate to your project's build target > **General** > **Embedded Binaries** > **+** and then add the `ObjectiveDropboxOfficial.framework` file for the iOS platform.

##### macOS
```bash
carthage update --platform Mac
```

Once you have checked-out out all the necessary code via Carthage, drag the `Carthage/Checkouts/ObjectiveDropboxOfficial/Source/ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.xcodeproj` file into your project as a subproject.

Then, in the Project Navigator in Xcode, select your project, and then navigate to your project's build target > **General** > **Embedded Binaries** > **+** and then add the `ObjectiveDropboxOfficial.framework` file for the macOS platform.

---

## Configure your project

Once you have integrated the Dropbox Objective-C SDK into your project, there are a few additional steps to take before you can begin making API calls.

### Application `.plist` file

If you are compiling on iOS SDK 9.0, you will need to modify your application's `.plist` to handle Apple's [new security changes](https://developer.apple.com/videos/wwdc/2015/?id=703) to the `canOpenURL` function. You should
add the following code to your application's `.plist` file:

```
<key>LSApplicationQueriesSchemes</key>
    <array>
        <string>dbapi-8-emm</string>
        <string>dbapi-2</string>
    </array>
```
This allows the Objective-C SDK to determine if the official Dropbox iOS app is installed on the current device. If it is installed, then the official Dropbox iOS app can be used to programmatically obtain an OAuth 2.0 access token.

Additionally, your application needs to register to handle a unique Dropbox URL scheme for redirect following completion of the OAuth 2.0 authorization flow. This URL scheme should have the format `db-<APP_KEY>`, where `<APP_KEY>` is your
Dropbox app's app key, which can be found in the [App Console](https://dropbox.com/developers/apps).

You should add the following code to your `.plist` file (but be sure to replace `<APP_KEY>` with your app's app key):

```
<key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>db-<APP_KEY></string>
            </array>
            <key>CFBundleURLName</key>
            <string></string>
        </dict>
    </array>
```

After you've made the above changes, your application's `.plist` file should look something like this:

<p align="center">
  <img src="https://github.com/dropbox/dropbox-sdk-obj-c/blob/master/Images/InfoPlistExample.png?raw=true" alt="Info .plist Example"/>
</p>

---

### Handling the authorization flow

There are three methods to programmatically retrieve an OAuth 2.0 access token:

* **Direct auth** (iOS only): This launches the official Dropbox iOS app (if installed), authenticates via the official app, then redirects back into the SDK
* **In-app webview auth** (iOS, macOS): This opens a pre-built in-app webview for authenticating via the Dropbox authorization page. This is convenient because the user is never redirected outside of your app.
* **External browser auth** (iOS, macOS): This launches the platform's default browser for authenticating via the Dropbox authorization page. This is desirable because it is safer for the end-user, and pre-existing session data can be used to avoid requiring the user to re-enter their Dropbox credentials.

To facilitate the above authorization flows, you should take the following steps:

---

#### Initialize a `DropboxClient` instance

##### iOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DropboxClientsManager setupWithAppKey:@"<APP_KEY>"];
    return YES;
}

```

##### macOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [DropboxClientsManager setupWithAppKeyDesktop:@"<APP_KEY>"];
}
```

---

#### Begin the authorization flow

You can commence the auth flow by calling `authorizeFromController:controller:openURL:browserAuth` method in your application's
view controller. If you wish to authenticate via the in-app webview, then set `browserAuth` to `NO`. Otherwise, authentication will be done via an external web browser.

##### iOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (void)myButtonInControllerPressed {
    [DropboxClientsManager authorizeFromController:[UIApplication sharedApplication]
                                        controller:self
                                           openURL:^(NSURL *url) {
                                                [[UIApplication sharedApplication] openURL:url];
                                           }
                                        browserAuth:YES];
}

```

##### macOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (void)myButtonInControllerPressed {
    [DropboxClientsManager authorizeFromControllerDesktop:[NSWorkspace sharedWorkspace]
                                        controller:self
                                           openURL:^(NSURL *url){ [[NSWorkspace sharedWorkspace] openURL:url]; }
                                       browserAuth:YES];
}
```

Beginning the authentication flow via in-app webview will launch a window like this:


<p align="center">
  <img src="https://github.com/dropbox/dropbox-sdk-obj-c/blob/master/Images/OAuthFlowInit.png?raw=true" alt="Auth Flow Init Example"/>
</p>

---

#### Handle redirect back into SDK

To handle the redirection back into the Objective-C SDK once the authentication flow is complete, you should add the following code in your application's delegate:

##### iOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    DBOAuthResult *authResult = [DropboxClientsManager handleRedirectURL:url];
    if (authResult != nil) {
        if ([authResult isSuccess]) {
            NSLog(@"Success! User is logged into Dropbox.");
        } else if ([authResult isCancel]) {
            NSLog(@"Authorization flow was manually canceled by user!");
        } else if ([authResult isError]) {
            NSLog(@"Error: %@", authResult);
        }
    }
    return NO;
}
```

For iOS targets >= 9, use:

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    DBOAuthResult *authResult = [DropboxClientsManager handleRedirectURL:url];
    ....
    ....
}
```

##### macOS

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

// generic launch handler
- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                     andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                   forEventClass:kInternetEventClass
                                                      andEventID:kAEGetURL];
}

// custom handler
- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    DBOAuthResult *authResult = [DropboxClientsManager handleRedirectURL:url];
    if (authResult != nil) {
        if ([authResult isSuccess]) {
            NSLog(@"Success! User is logged into Dropbox.");
        } else if ([authResult isCancel]) {
            NSLog(@"Authorization flow was manually canceled by user!");
        } else if ([authResult isError]) {
            NSLog(@"Error: %@", authResult);
        }
    }
}
```

After the end user signs in with their Dropbox login credentials via the in-app webview, they will see a window like this:


<p align="center">
  <img src="https://github.com/dropbox/dropbox-sdk-obj-c/blob/master/Images/OAuthFlowApproval.png?raw=true" alt="Auth Flow Approval Example"/>
</p>

If they press **Allow** or **Cancel**, the `db-<APP_KEY>` redirect URL will be launched from the webview, and will be handled in your application
delegate's `application:handleOpenURL` method, from which the result of the authorization can be parsed.

Now you're ready to begin making API requests!

---

## Try some API requests

Once you have obtained an OAuth 2.0 token, you can try some API v2 calls using the Objective-C SDK.

### Dropbox client instance

Start by creating a reference to the `DropboxClient` or `DropboxTeamClient` instance that you will use to make your API calls.

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

// Reference after programmatic auth flow
DropboxClient *client = [DropboxClientsManager authorizedClient];
```

or

```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

// Initialize with manually retrieved auth token
DropboxClient *client = [[DropboxClient alloc] initWithAccessToken:@"<MY_ACCESS_TOKEN>"];
```

---

### Handle the API response

The Dropbox [User API](https://www.dropbox.com/developers/documentation/http/documentation) and [Business API](https://www.dropbox.com/developers/documentation/http/teams) have three types of requests: RPC, Upload and Download.

The response handlers for each request type are similar to one another. The arguments for the handler blocks are as follows:
* **route result type** (`DBNilObject` if the route does not have a return type)
* **route-specific error** (usually a union type)
* **network request error** (generic to all requests -- contains information like request ID, HTTP status code, etc.)
* **output content** (`NSURL` / `NSData` reference to downloaded output for Download-style endpoints only)

Response handlers are required for all endpoints. Progress handlers, on the other hand, are optional for all endpoints.

> Note: The Objective-C SDK uses `NSNumber` objects in place of boolean values. This is done so that nullability can be represented in some of our API response values. For this reason, you should be careful when writing checks like `if (myAPIObject.isSomething)`, which is checking nullability rather than value. Instead, you should use `if ([myAPIObject.isSomething boolValue])`, which converts the `NSNumber` field to a boolean value before using it in the if check.

---

### Request types

#### RPC-style request
```objective-c
[[client.filesRoutes createFolder:@"/test/path"]
    response:^(DBFILESFolderMetadata *result, DBFILESCreateFolderError *routeError, DBRequestError *error) {
        if (result) {
            NSLog(@"%@\n", result);
        } else {
            NSLog(@"%@\n%@\n", routeError, error);
        }
    }];
```

---

#### Upload-style request
```objective-c
NSData *fileData = [@"file data example" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
[[[client.filesRoutes uploadData:@"/test/path/in/Dropbox/account" inputData:fileData]
    response:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBRequestError *error) {
        if (result) {
            NSLog(@"%@\n", result);
        } else {
            NSLog(@"%@\n%@\n", routeError, error);
        }
    }] progress:^(int64_t bytesUploaded, int64_t totalBytesUploaded, int64_t totalBytesExpectedToUploaded) {
        NSLog(@"\n%lld\n%lld\n%lld\n", bytesUploaded, totalBytesUploaded, totalBytesExpectedToUploaded);
    }];

// ADVANCED UPLOAD USE CASES
// To batch upload files or to chunk upload large files, use the custom `batchUploadFiles` route

NSMutableDictionary<NSURL *, DBFILESCommitInfo *> *uploadFilesUrlsToCommitInfo = [NSMutableDictionary new];
DBFILESCommitInfo *commitInfo =
    [[DBFILESCommitInfo alloc] initWithPath:@"/output/path/in/Dropbox"];
[uploadFilesUrlsToCommitInfo setObject:commitInfo forKey:@"/local/path/to/my/file"];

[_tester.files batchUploadFiles:uploadFilesUrlsToCommitInfo
                            queue:nil
                    progressBlock:^(int64_t uploaded, int64_t total, int64_t expectedTotal) {
    NSLog(@"Uploaded: %lld  UploadedTotal: %lld  ExpectedToUploadTotal: %lld", uploaded, total, expectedTotal);
} responseBlock:^(DBFILESUploadSessionFinishBatchJobStatus *result, DBASYNCPollError *routeError, DBRequestError *error) {
    if (result) {
      NSLog(@"%@\n", result);
    } else {
      NSLog(@"%@  %@\n", routeError, error);
    }
}];

// note: with this method, response and progress handlers are passed directly into the route as arguments
```

---

#### Download-style request
```objective-c
// Download to NSURL
NSFileManager *fileManager = [NSFileManager defaultManager];
NSURL *outputDirectory = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
NSURL *outputUrl = [outputDirectory URLByAppendingPathComponent:@"test_file_output.txt"];
[[[client.filesRoutes downloadUrl:@"/test/path/in/Dropbox/account" overwrite:YES destination:outputUrl]
    response:^(DBFILESFileMetadata *result, DBFILESDownloadError *routeError, DBRequestError *error, NSURL *destination) {
        if (result) {
            NSLog(@"%@\n", result);
            NSData *data = [[NSFileManager defaultManager] contentsAtPath:[destination path]];
            NSString *dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@\n", dataStr);
        } else {
            NSLog(@"%@\n%@\n", routeError, error);
        }
    }] progress:^(int64_t bytesDownloaded, int64_t totalBytesDownloaded, int64_t totalBytesExpectedToDownload) {
        NSLog(@"%lld\n%lld\n%lld\n", bytesDownloaded, totalBytesDownloaded, totalBytesExpectedToDownload);
    }];


// Download to NSData
[[[client.filesRoutes downloadData:@"/test/path"]
    response:^(DBFILESFileMetadata *result, DBFILESDownloadError *routeError, DBRequestError *error, NSData *fileContents) {
        if (result) {
            NSLog(@"%@\n", result);
            NSString *dataStr = [[NSString alloc]initWithData:fileContents encoding:NSUTF8StringEncoding];
            NSLog(@"%@\n", dataStr);
        } else {
            NSLog(@"%@\n%@\n", routeError, error);
        }
    }] progress:^(int64_t bytesDownloaded, int64_t totalBytesDownloaded, int64_t totalBytesExpectedToDownload) {
        NSLog(@"%lld\n%lld\n%lld\n", bytesDownloaded, totalBytesDownloaded, totalBytesExpectedToDownload);
    }];
```

---

### Handling responses and errors

Dropbox API v2 deals largely with two data types: **structs** and **unions**. Broadly speaking, most route **arguments** are struct types and most route **errors** are union types.

**NOTE:** In this context, "structs" and "unions" are terms specific to the Dropbox API, and not to any of the languages that are used to query the API, so you should avoid thinking of them in terms of their Objective-C definitions.

**Struct types** are "traditional" object types, that is, composite types made up of a collection of one or more instance fields. All public instance fields are accessible at runtime, regardless of runtime state.

**Union types**, on the other hand, represent a single value that can take on multiple value types, depending on state. We capture all of these different type scenarios under one "union object", but that object will exist only as one type at runtime. Each union state type, or **tag**, may have an associated value (if it doesn't, the union state type is said to be **void**). Associated value types can either be primitives, structs or unions. Although the Objective-C SDK represents union types as objects with multiple instance fields, at most one instance field is accessible at runtime, depending on the tag state of the union.

For example, the [/delete](https://www.dropbox.com/developers/documentation/http/documentation#files-delete) endpoint returns an error, `DeleteError`, which is a union type. The `DeleteError` union can take on two different tag states: `path_lookup`
(if there is a problem looking up the path) or `path_write` (if there is a problem writing -- or in this case deleting -- to the path). Here, both tag states have non-void associated values (of types `DBFILESLookupError` and `DBFILESWriteError`, respectively).

In this way, one union object is able to capture a multitude of scenarios, each of which has their own value type.

To properly handle union types, you should call each of the `is<TAG_STATE>` methods associated with the union. Once you have determined the current tag state of the union, you can then safely access the value associated with that tag state (provided there exists an associated value type, i.e., it's not **void**).
If at run time you attempt to access a union instance field that is not associated with the current tag state, **an exception will be thrown**. See below:

---

#### Route-specific errors
```objective-c
[[client.filesRoutes delete_:@"/test/path"]
    response:^(DBFILESMetadata *result, DBFILESDeleteError *routeError, DBRequestError *error) {
        if (result) {
            NSLog(@"%@\n", result);
        } else {
            // Error is with the route specifically (status code 409)
            if (routeError) {
                if ([routeError isPathLookup]) {
                    // Can safely access this field
                    DBFILESLookupError *pathLookup = routeError.pathLookup;
                    NSLog(@"%@\n", pathLookup);
                } else if ([routeError isPathWrite]) {
                    DBFILESWriteError *pathWrite = routeError.pathWrite;
                    NSLog(@"%@\n", pathWrite);

                    // This would cause a runtime error
                    // DBFILESLookupError *pathLookup = routeError.pathLookup;
                }
            }
            NSLog(@"%@\n%@\n", routeError, error);
        }
    }];
```

---

#### Generic network request errors

In the case of a network error, regardless of whether the error is specific to the route, a generic `DBRequestError` type will always be returned, which includes information like Dropbox request ID and HTTP status code.

The `DBRequestError` type is a special union type which is similar to the standard API v2 union type, but also includes a collection of `as<TAG_STATE>` methods, each of which returns a new instance of a particular error subtype.
As with accessing associated values in regular unions, the `as<TAG_STATE>` should only be called after the corresponding `is<TAG_STATE>` method returns true. See below:

```objective-c
[[client.filesRoutes delete_:@"/test/path"]
    response:^(DBFILESMetadata *result, DBFILESDeleteError *routeError, DBRequestError *error) {
        if (result) {
            NSLog(@"%@\n", result);
        } else {
            if (routeError) {
                // see handling above
            }
            // Error not specific to the route (status codes 500, 400, 401, 403, 404, 429)
            else {
                if ([error isInternalServerError]) {
                    DBRequestInternalServerError *internalServerError = [error asInternalServerError];
                    NSLog(@"%@\n", internalServerError);
                } else if ([error isBadInputError]) {
                    DBRequestBadInputError *badInputError = [error asBadInputError];
                    NSLog(@"%@\n", badInputError);
                } else if ([error isAuthError]) {
                    DBRequestAuthError *authError = [error asAuthError];
                    NSLog(@"%@\n", authError);
                } else if ([error isAccessError]) {
                    DBRequestAccessError *accessError = [error asAccessError];
                    NSLog(@"%@\n", accessError);
                } else if ([error isRateLimitError]) {
                    DBRequestRateLimitError *rateLimitError = [error asRateLimitError];
                    NSLog(@"%@\n", rateLimitError);
                } else if ([error isHttpError]) {
                    DBRequestHttpError *genericHttpError = [error asHttpError];
                    NSLog(@"%@\n", genericHttpError);
                } else if ([error isClientError]) {
                    DBRequestClientError *genericLocalError = [error asClientError];
                    NSLog(@"%@\n", genericLocalError);
                }
            }
        }
    }];
```

---

#### Response handling edge cases

Some routes return union types as result types, so you should be prepared to handle these results in the same way that you handle union route errors. Please consult the [documentation](https://www.dropbox.com/developers/documentation/http/documentation)
for each endpoint that you use to ensure you are properly handling the route's response type.

A few routes return result types that are **datatypes with subtypes**, that is, structs that can take on multiple state types like unions.

For example, the [/delete](https://www.dropbox.com/developers/documentation/http/documentation#files-delete) endpoint returns a generic `Metadata` type, which can exist either as a `FileMetadata` struct, a `FolderMetadata` struct, or a `DeletedMetadata` struct.
To determine at runtime which subtype the `Metadata` type exists as, perform an `isKindOfClass` check for each possible class, and then cast the result accordingly. See below:

```objective-c
[[client.filesRoutes delete_:@"/test/path"]
    response:^(DBFILESMetadata *result, DBFILESDeleteError *routeError, DBRequestError *error) {
        if (result) {
            if ([result isKindOfClass:[DBFILESFileMetadata class]]) {
                DBFILESFileMetadata *fileMetadata = (DBFILESFileMetadata *)result;
                NSLog(@"%@\n", fileMetadata);
            } else if ([result isKindOfClass:[DBFILESFolderMetadata class]]) {
                DBFILESFolderMetadata *folderMetadata = (DBFILESFolderMetadata *)result;
                NSLog(@"%@\n", folderMetadata);
            } else if ([result isKindOfClass:[DBFILESDeletedMetadata class]]) {
                DBFILESDeletedMetadata *deletedMetadata = (DBFILESDeletedMetadata *)result;
                NSLog(@"%@\n", deletedMetadata);
            }
        } else {
            if (routeError) {
                // see handling above
            } else {
                // see handling above
            }
        }
    }];
```

This `Metadata` object is known as a **datatype with subtypes** in our API v2 documentation.

Datatypes with subtypes are a way combining structs and unions. Datatypes with subtypes are struct objects that contain a tag, which specifies which subtype the object exists as at runtime. The reason we have this construct, as with unions, is so we can capture a multitude of scenarios with one object.

In the above example, the `Metadata` type can exists as `FileMetadata`, `FolderMetadata` or `DeleteMetadata`. Each of these types have common instances fields like "name" (the name for the file, folder or deleted type), but also instance fields that are specific to the particular subtype. In order to leverage inheritance, we set a common supertype called `Metadata` which captures all of the common instance fields, but also has a tag instance field, which specifies which subtype the object currently exists as.

In this way, datatypes with subtypes are a hybrid of structs and unions. Only a few routes return result types like this.

---

### Customizing network calls

#### Configure network client

It is possible to configure the networking client used by the SDK to make API requests. You can supply custom fields like a custom user agent or custom delegate queue to manage response handler code. See below:

##### iOS
```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

DBTransportClient *transportClient = [[DBTransportClient alloc] initWithAccessToken:nil
                                                                         selectUser:nil
                                                                          baseHosts:nil
                                                                          userAgent:@"CustomUserAgent"
                                                                backgroundSessionId:@"com.custom.background.session.id"
                                                                             appKey:(NSString *)@"<APP_KEY>"
                                                                          appSecret:(NSString *)@"<APP_SECRET>"
                                                                      delegateQueue:[NSOperationQueue new]];
[DropboxClientsManager setupWithAppKey:@"<APP_KEY>" transportClient:transportClient];
```

##### macOS
```objective-c
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

DBTransportClient *transportClient = [[DBTransportClient alloc] initWithAccessToken:nil
                                                                         selectUser:nil
                                                                          baseHosts:nil
                                                                          userAgent:@"CustomUserAgent"
                                                                backgroundSessionId:@"com.custom.background.session.id"
                                                                             appKey:(NSString *)@"<APP_KEY>"
                                                                          appSecret:(NSString *)@"<APP_SECRET>"
                                                                      delegateQueue:[NSOperationQueue new]];
[DropboxClientsManager setupWithAppKeyDesktop:@"<APP_KEY>" transportClient:transportClient];
```

#### Specify API call response queue

By default, response/progress handler code runs on the main thread. You can set a custom response queue for each API call that you make via the `response` method, in the event want your response/progress handler code to run on a different thread:

```objective-c
[[client.filesRoutes listFolder:@""]
    response:[NSOperationQueue new] response:^(DBFILESListFolderResult *result, DBFILESListFolderError *routeError, DBRequestError *error) {
        if (result) {
          NSLog(@"%@", [NSThread currentThread]);  // Output: <NSThread: 0x600000261480>{number = 5, name = (null)}
          NSLog(@"%@", [NSThread mainThread]);     // Output: <NSThread: 0x618000062bc0>{number = 1, name = (null)}
          NSLog(@"%@\n", result);
        }
    }];
```

---

### `DropboxClientsManager` class

The Objective-C SDK includes a convenience class, `DropboxClientsManager`, for integrating the different functions of the SDK into one class.

#### Single Dropbox user case

For most apps, it is reasonable to assume that only one Dropbox account (and access token) needs to be managed at a time. In this case, the `DropboxClientsManager` flow looks like this: 

* call `setupWithAppKey`/`setupWithAppKeyDesktop` (or `setupWithTeamAppKey`/`setupWithTeamAppKeyDesktop`) in integrating app's app delegate
* client manager determines whether any access tokens are stored -- if any exist, one token is arbitrarily chosen to use
* if no token is found, call `authorizeFromController`/`authorizeFromControllerDesktop` to initiate the OAuth flow
* if auth flow is initiated, call `handleRedirectURL` (or `handleRedirectURLTeam`) in integrating app's app delegate to handle auth redirect back into the app and store the retrieved access token (using a `DBOAuthManager` instance)
* client manager instantiates a `DBTransportClient` (if not supplied by the user)
* client manager instantiates a `DropboxClient` (or `DropboxTeamClient`) with the transport client as a field

The `DropboxClient` (or `DropboxTeamClient`) is then used to make all of the desired API calls.

* call `unlinkClients` to logout Dropbox user and clear all access tokens

#### Multiple Dropbox user case

For some apps, it is necessary to manage more than one Dropbox account (and access token) at a time. In this case, the `DropboxClientsManager` flow looks like this: 

* access token uids are managed by the app that is integrating with the SDK for later lookup
* call `setupWithAppKeyMultiUser`/`setupWithAppKeyMultiUserDesktop` (or `setupWithTeamAppKeyMultiUser`/`setupWithTeamAppKeyMultiUserDesktop`) in integrating app's app delegate
* client manager determines whether an access token is stored with the`tokenUid` as a key -- if one exists, this token is chosen to use
* if no token is found, call `authorizeFromController`/`authorizeFromControllerDesktop` to initiate the OAuth flow
* if auth flow is initiated, call `handleRedirectURL` (or `handleRedirectURLTeam`) in integrating app's app delegate to handle auth redirect back into the app and store the retrieved access token (using a `DBOAuthManager` instance)
* at this point, the app that is integrating with the SDK should persistently save the `tokenUid` from the `DBAccessToken` field of the `DBOAuthResult` object returned from the `handleRedirectURL` (or `handleRedirectURLTeam`) method
* `tokenUid` can be reused either to authorize a new user mid-way through an app's lifecycle via `reauthorizeClient` (or `reauthorizeTeamClient`) or when the app initially launches via `setupWithAppKeyMultiUser`/`setupWithAppKeyMultiUserDesktop` (or `setupWithTeamAppKeyMultiUser`/`setupWithTeamAppKeyMultiUserDesktop`)
* client manager instantiates a `DBTransportClient` (if not supplied by the user)
* client manager instantiates a `DropboxClient` (or `DropboxTeamClient`) with the transport client as a field

The `DropboxClient` (or `DropboxTeamClient`) is then used to make all of the desired API calls.

* call `resetClients` to logout Dropbox user but not clear any access tokens
* if specific access tokens need to be removed, use the `clearStoredAccessToken` method in `DBOAuthManager`

---

## Examples

Example projects that demonstrate how to integrate your app with the SDK can be found in the `Examples/` folder.

* [DBRoulette](https://github.com/dropbox/dropbox-sdk-obj-c/tree/master/Examples/DBRoulette/) - Play a fun game of photo roulette with the image files in your Dropbox!

---

## Documentation

* [Dropbox API v2 Objective-C SDK](http://dropbox.github.io/dropbox-sdk-obj-c/api-docs/latest/)
* [Dropbox API v2](https://www.dropbox.com/developers/documentation/http/documentation)

---

## Stone

All of our routes and data types are auto-generated using a framework called [Stone](https://github.com/dropbox/stone).

The `stone` repo contains all of the Objective-C specific generation logic, and the `spec` repo contains the language-neutral API endpoint specifications which serve
as input to the language-specific generators.

---

## Modifications

If you're interested in modifying the SDK codebase, you should take the following steps:

* clone this GitHub repository to your local filesystem
* run `git submodule init` and then `git submodule update`
* navigate to `TestObjectiveDropbox` and run `pod install`
* open `TestObjectiveDropbox/TestObjectiveDropbox.xcworkspace` in Xcode
* implement your changes to the SDK source code.

To ensure your changes have not broken any existing functionality, you can run a series of integration tests by
following the instructions listed in the `ViewController.m` file.

---

## Bugs

Please post any bugs to the [issue tracker](https://github.com/dropbox/dropbox-sdk-obj-c/issues) found on the project's GitHub page.
  
Please include the following with your issue:
 - a description of what is not working right
 - sample code to help replicate the issue

Thank you!


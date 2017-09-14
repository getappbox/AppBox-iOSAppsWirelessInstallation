# Google-Analytics-for-OS-X
Google Analytics SDK for OS X

This is an Objective-C wrapper around [Measurement Protocol](https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide)

## Installation
Google-Analytics-for-OS-X is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Google-Analytics-for-OS-X"
```

Alternatively, you can just clone the repo, build `GoogleAnalyticsTracker` target and use the framework in your project.

## Usage

```
    MPAnalyticsConfiguration *configuration = [[MPAnalyticsConfiguration alloc] initWithAnalyticsIdentifier:@"UA-TEST-X"];
    [MPGoogleAnalyticsTracker activateConfiguration:configuration];
```

#### Track Event

```
    [MPGoogleAnalyticsTracker trackEventOfCategory:@"Interaction" action:@"Button Click"
                                             label:@"Track Event Button" value:@0];
```

#### Track Timing

```
    [MPGoogleAnalyticsTracker trackTimingOfCategory:@"Timings" variable:@"App Launch Duration"
                                               time:@100 label:@""];
```

#### Debug Window

There is a special debug window included in the framework. It can be used by developers/QA/marketing for testing.

![ScreenShot](https://raw.githubusercontent.com/MacPaw/Google-Analytics-for-OS-X/master/screenshot.png)

#License

Google-Analytics-for-OS-X is licensed under the MIT License. See the LICENSE file for more information.


---
hide:
  - toc
---

# Keep Same Link
## 1. What is keep same link?
This feature will keep same short URL for all future build/IPA uploaded with same bundle identifier. If this option is enabled, you can also download the previous build with the same URL.

When you've uploaded more than one app with "Keep Same Link" option enable and open the short URL in your iOS Device, you'll see two option is there

![](../Images/ABKeepSameLink.webp)

#### 1.1. Install Application
Install Application button will always install the latest build.

#### 1.2. Install the Previous Build
The "Install Previous Version(s)" button opens a new page displaying a list of all uploaded versions, including their dates and times (device local time). You can install any previous build from this page.

![](../Images/ABWebInstallPreviousHome.webp)  ![](../Images/ABWebInstallPrevious.webp)

## 2. How to create two different links for the same build using Keep Same Link option?
You can change the link by providing a "Custom Dropbox Folder Name" in "Other Setting". By default folder name will be the application bundle identifier. AppBox will keep the same link for the IPA file available in the same folder.
![](../Images/ABChangeFolder.webp)

## 3. How to keep the same link but also hide the previous version from the installation page?
You can do this from AppBox preferences by enabling "Don't show the previous version on app installation page"  option.
Now, if you enabled "Keep Same Link" during upload and this option is enabled, the AppBox installation page will not display previous versions.
![](../Images/ABDontShowOldBuild.webp)
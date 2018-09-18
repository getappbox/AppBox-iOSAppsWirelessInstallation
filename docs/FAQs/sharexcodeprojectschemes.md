# How to share Xcode Project Schemes?

Schemes that are not marked shared in Xcode cannot be built outside Xcode, and this affects a CI server like Jenkins and other as well. Here the process of sharing a Xcode project scheme:

Navigate to `Product` -> `Scheme` -> `Manage Schemes`

You will see a list of schemes, with each denoted as being shared or not. Make sure that the shared checkbox for your scheme is marked, then click OK. Finally, once you have marked the scheme as shared, you will have to add the files that Xcode has generated to your git repository as well.


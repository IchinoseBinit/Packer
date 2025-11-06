fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Build release APK

### android upload_apk

```sh
[bundle exec] fastlane android upload_apk
```

Upload built APK to Google Drive

### android build_aab

```sh
[bundle exec] fastlane android build_aab
```

Build release AAB (App Bundle)

### android upload_internal

```sh
[bundle exec] fastlane android upload_internal
```

Upload AAB to Internal App Sharing

### android upload_production

```sh
[bundle exec] fastlane android upload_production
```

Upload AAB to Google Play Production

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

# CHANGELOG

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a Changelog](http://keepachangelog.com/).



## [Unreleased] - YYYY-MM-DD

### Added

### Changed

### Fixed

### Security

### Removed


## [1.0.1+2] - 2026-01-22

### Added
- Add app icon with "launcher_icon", using the image in `assets/docs/images/gs_logo_circle.png`
- Add "make build_bundle" to build the AAB (Android App Bundle) in the Google Play Store
- Add "make generate_keystore" to generate the keystore to be used to sign the AAB in the Google Play Store
- Add "make sign_apk" to sign the APK (Android App Package)
- Add "make sign_bundle" to sign the AAB (Android App Bundle)
- Add "make generate_icons" to generate the app icons
- Add "make create_android_avd" to create an Android AVD (Android Virtual Device)

### Changed
- Change the name of the app in both Android and iOS, so its name in the phone is "GS Doc" instead of "gs_docs_viewer"
- Upgrade to Flutter 3.38.7, Kotlin 2.1.0, iOS MinimumOSVersion 13.0
- Use Gradle version 9.3.0; compileSdk changed from 35 to 36; ndkVersion changed from "25.1.8937393" to "27.0.12077973"
- Androd namespace is "com.genericsuite.gs_docs_viewer", and iOS product bundle identifier is "com.genericsuite.gsdoc"
- Rename "make unbuild" to "make clean_build"

### Fixed
- Internal and external links don't work
- Images are not showing on Android app.


## [1.0.0+1] - 2026-01-21

### Added
- Initial release
- Privacy policy in. GS Basecamp
- Make it work for Google Play Store

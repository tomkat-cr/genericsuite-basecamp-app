# CHANGELOG

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a Changelog](http://keepachangelog.com/).



## [Unreleased] - YYYY-MM-DD

### Added

### Changed

### Fixed

### Security

### Removed


## [Unreleased] - 2026-04-19

### Added
- AGENTS.md, GEMINI.md, and CLAUDE.md files to provide context and instructions to AI Coding Assistants [GS-303].
- Add SAST testing [GS-315].
- `GS_BASECAMP_PATH` environment variable to specify the path to the GenericSuite Basecamp repository.
- `README.md` content with pre-requisites, installation and usage instructions [GS-303].
- `make open-ios-simulator` to open the Apple iOS simulator.
- `open-android-emulator` and the `open-android-emulator.sh` script.

### Changed
- `run_docs_converter.sh` will clone the GenericSuite Basecamp repo in the `./genericsuite-basecamp` directory if `GS_BASECAMP_PATH` is empty, otherwise it will use the path specified in `GS_BASECAMP_PATH`.

### Removed
- Git submodule genericsuite-basecamp


## [1.0.0+3] - 2026-01-25

### Added
- Spanish docs, using Google Translate and OpenAI gpt-5-nano, thanks to @otobonh [GS-252].
- Language selection in the app menu [GS-252].
- Back button to go back to the previous page [GS-252].
- "getLangForApp" function to get the configured device language [GS-252].
- "make translate_uncommitted" command to translate uncommitted changes in the `genericsuite_basecamp/docs` directory [GS-252].

### Changed
- Refactor documentation conversion process [GS-252]:
    - Convert all separated functions to a single class DocsConverter
    - Turn off translatiion by default (self.translation = False)
    - Add a "--translation" parameter to enable translation
    - Add ignore files paths
    - Change "assets/docs_en" to "assets/docs/en", and "assets/docs_es" to "assets/docs/es", following the multi-language support addition to genericsuite_basecamp
- Update documentation asset paths and image resolution, following the multi-language support addition to genericsuite_basecamp [GS-252]

### Fixed
- Remove <BR/> before show the content [GS-252].
- Add additional lines at the content end for those cases when the device has a the "pin the home screen design" configration enabled [GS-252].
- Fix the banner size on the app menu [GS-252].


## [1.0.1+2] - 2026-01-22

### Added
- Add app icon with "launcher_icon", using the image in `assets/docs/images/gs_logo_circle.png` [GS-252].
- Add "make build_bundle" to build the AAB (Android App Bundle) in the Google Play Store [GS-252].
- Add "make generate_keystore" to generate the keystore to be used to sign the AAB in the Google Play Store [GS-252].
- Add "make sign_apk" to sign the APK (Android App Package) [GS-252].
- Add "make sign_bundle" to sign the AAB (Android App Bundle) [GS-252].
- Add "make generate_icons" to generate the app icons [GS-252].
- Add "make create_android_avd" to create an Android AVD (Android Virtual Device) [GS-252].

### Changed
- Change the name of the app in both Android and iOS, so its name in the phone is "GS Doc" instead of "gs_docs_viewer" [GS-252].
- Upgrade to Flutter 3.38.7, Kotlin 2.1.0, iOS MinimumOSVersion 13.0 [GS-252].
- Use Gradle version 9.3.0; compileSdk changed from 35 to 36; ndkVersion changed from "25.1.8937393" to "27.0.12077973" [GS-252].
- Androd namespace is "com.genericsuite.gs_docs_viewer", and iOS product bundle identifier is "com.genericsuite.gsdoc" [GS-252].
- Rename "make unbuild" to "make clean_build" [GS-252].

### Fixed
- Internal and external links don't work [GS-252].
- Images are not showing on Android app [GS-252].


## [1.0.0+1] - 2026-01-21

### Added
- Initial release [GS-252].
- Privacy policy in GS Basecamp [GS-252].
- Make it work for Google Play Store [GS-252].

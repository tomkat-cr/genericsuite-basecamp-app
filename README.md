# Genericsuite Documentation Mobile App

**GS Doc** is a Flutter mobile app that serves as a documentation viewer for GenericSuite Basecamp. Documentation is bundled as assets (no runtime downloads), supports English/Spanish with auto-detection from device locale, and uses Markdown rendering with custom image/link handling.

## Requirements

- Flutter 3.38.7+, Dart SDK 3.5.4+
- Python 3.9+
- Git
- Make

## Usage

### Clone the repository

```bash
git clone https://github.com/tomkat-cr/genericsuite-basecamp-app.git
cd genericsuite-basecamp-app
```

### Install dependencies

```bash
make install
```

## Set Environment Variables

Copy `.env.example` to `.env`. Required only for documentation generation scripts:

| Variable | Purpose |
|---|---|
| `GS_BASECAMP_PATH` | Path to local GenericSuite Basecamp repo; if empty, scripts clone it to `./genericsuite-basecamp` |
| `OPENAI_API_KEY` | OpenAI API key for AI-powered Spanish translation |
| `OPENAI_MODEL` | Model for translation (default: `gpt-5-nano`; alternative: `gpt-4o-mini`) |
| `OPENAI_TEMPERATURE` | Temperature for API calls (default: `1`; range: `0.3–1`) |

### Run the Emulator

```bash
# Apple iOS / iPhone emulator
make open-ios-simulator
```

Or...

```bash
# Android emulator
make open-android-emulator
# Or set a specific AVD name:
# AVD_NAME=Pixel_8A make open-android-emulator
```

### Run the app

```bash
make run
```

If `make run` doesn't work, try to run with the Fluuer extension in your editor (Visual Studio Code, Cursor, Antigravity):

- Install the [Flutter extension for VSCode](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- Right-click on the [lib/main.dart](./lib/main.dart) file and select `Start debugging` option

## Common Commands

```bash
make install          # Install Flutter dependencies (flutter pub get)
make run              # Clean logs and run on device/emulator
make build_local      # Build debug APK
make build            # Build release APK
make build_bundle     # Build AAB for Google Play Store
make fresh            # Clean + reinstall dependencies
make update_documentation  # Pull docs from GenericSuite Basecamp and generate assets
make translate_uncommitted  # Translate uncommitted English docs to Spanish
make sast-test        # Run Snyk security scanning
make generate_icons   # Regenerate app icons from assets/docs/assets/images/gs_logo_circle.png
make sign_apk         # Sign APK with keystore
make sign_bundle      # Sign AAB with keystore
```

## Platform Targets

- **Android**: Primary target; APK and AAB builds. `compileSdk 36`, `ndkVersion 27.0.12077973`, Kotlin 2.1.0, Gradle 9.3.0. Package: `com.genericsuite.gs_docs_viewer`
- **iOS**: Configured; minimum OS 13.0. Bundle ID: `com.genericsuite.gsdoc`
- Web/macOS/Linux/Windows platform directories exist but are not the focus

## License

This project is licensed under the [MIT License](https://github.com/tomkat-cr/genericsuite-basecamp-app/blob/main/LICENSE).

## Credits

This project is developed and maintained by [Carlos Ramirez](https://www.carlosjramirez.com). For more information or to contribute to the project, visit [GenericSuite on GitHub](https://github.com/tomkat-cr/genericsuite-basecamp-app).

Happy Coding!

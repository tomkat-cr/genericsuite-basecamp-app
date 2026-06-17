# CLAUDE.md

This file provides guidance to AI Coding Assistants (Claude Code, Gemini CLI, Cursor, Antigravity, etc.) when working with code in this repository.

## Project Overview

**GS Doc** is a Flutter mobile app that serves as a documentation viewer for GenericSuite Basecamp. Documentation is bundled as assets (no runtime downloads), supports English/Spanish with auto-detection from device locale, and uses Markdown rendering with custom image/link handling.

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
make generate_icons   # Regenerate app icons from assets/mkdocs_root/assets/images/gs_logo_circle.png
make sign_apk         # Sign APK with keystore
make sign_bundle      # Sign AAB with keystore
```

## Environment Variables

Copy `.env.example` to `.env`. Required only for documentation generation scripts:

| Variable | Purpose |
|---|---|
| `GS_BASECAMP_PATH` | Path to local GenericSuite Basecamp repo; if empty, scripts clone it to `./genericsuite-basecamp` |
| `OPENAI_API_KEY` | OpenAI API key for AI-powered Spanish translation |
| `OPENAI_MODEL` | Model for translation (default: `gpt-5-nano`; alternative: `gpt-4o-mini`) |
| `OPENAI_TEMPERATURE` | Temperature for API calls (default: `1`; range: `0.3–1`) |

## Architecture

### State Management & Navigation

The app uses **Provider** for state management with `MultiProvider` at the root. Navigation is drawer-based (not Navigator-driven routes): `DocViewerScreen` tracks visited pages in a simple `_previousPage` variable (not a full stack), enabling a single-level back button.

### Documentation Pipeline

1. `scripts/run_docs_converter.sh` — orchestrator: sets up Python venv, clones/pulls the `genericsuite-basecamp` repo, runs the converter
2. `scripts/docs_converter.py` — `DocsConverter` class: reads `genericsuite-basecamp/mkdocs_root/{en,es}/`, copies to `assets/mkdocs_root/{lang}/`, and generates `assets/docs_manifest.json` (the navigation tree)
3. `scripts/translate_ai_module.py` — wraps OpenAI + Google Translate fallback for Spanish translation; translation is **off by default** in the converter (pass `--translation` to enable)

### Key Files

| File | Role |
|---|---|
| `lib/main.dart` | App init, `GsDoc` root widget, `HomeScreen` with `DocViewerScreen` embedding |
| `lib/services/doc_service.dart` | Loads `assets/docs_manifest.json`; provides `getFirstPage()` |
| `lib/models/doc_manifest.dart` | `DocManifestItem` model; `DocManifestLoader` JSON parser |
| `lib/screens/doc_viewer_screen.dart` | Core markdown viewer: path resolution, language-aware asset loading, anchor detection, back button, external URL launching |
| `lib/screens/doc_drawer.dart` | Expandable nav drawer with EN/ES language toggle |
| `lib/services/utilities.dart` | Logging, URL launcher, `getLangForApp()` (device locale detection) |

### Asset Structure

```
assets/
├── docs_manifest.json          # Generated navigation tree
└── mkdocs_root/
    ├── assets/images/          # Shared images (logos)
    ├── code/                   # Example code
    ├── en/                     # English markdown docs
    └── es/                     # Spanish markdown docs (translated)
```

Language-aware paths follow the pattern `assets/mkdocs_root/{lang}/{relative-path}`. `DocViewerScreen` resolves relative links and `../assets/images/` paths against the current document's base path.

### Known Limitations / TODOs in Code

- Anchor links (`#section`) are partially implemented (header detection exists but scrolling is not wired)
- FontAwesome icons have a placeholder preprocessor (`fontawesome_service.dart`) — not fully functional
- `make test` target has a TODO; the only test is a placeholder smoke test in `test/widget_test.dart`

## Platform Targets

- **Android**: Primary target; APK and AAB builds. `compileSdk 36`, `ndkVersion 27.0.12077973`, Kotlin 2.1.0, Gradle 9.3.0. Package: `com.genericsuite.gs_docs_viewer`
- **iOS**: Configured; minimum OS 13.0. Bundle ID: `com.genericsuite.gsdoc`
- Web/macOS/Linux/Windows platform directories exist but are not the focus

## Flutter Version Requirements

- Flutter 3.38.7+, Dart SDK 3.5.4+
- Use `flutter_lints` (v4) — `analysis_options.yaml` enforces recommended linting

## Important Notes

- The files `AGENTS.md`, `GEMINI.md`, etc. (if present) have only a referece to `@CLAUDE.md` — edit only `CLAUDE.md`.
- Skills live in `.ai/skills/` (source of truth); symlinked under `.agents/skills/`, `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`, and `.devin/skills/`.

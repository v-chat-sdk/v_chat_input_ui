# Repository Guidelines

## Project Structure & Module Organization

This repository is the `v_chat_input_ui` Flutter package. `lib/v_chat_input_ui.dart` is the public entry point; keep exported API additions explicit there. Implementation code lives in `lib/src/`, grouped into `input/` widgets, `recorder/`, `models/`, and shared `v_widgets/`. Package tests belong in `test/`. The `example/` directory is a standalone Flutter application with its own `lib/`, `test/`, and platform runners; use it for integration and visual checks. Do not commit generated `.dart_tool/`, `build/`, IDE, or plugin-registration files.

## Flutter 3.50 verification workflow

Use the installed project-compatible Flutter 3.50/Dart 3.14 SDK. Keep direct `material_ui`/`cupertino_ui` dependencies consistent with their imports; design widgets no longer come from `flutter/material.dart` or `flutter/cupertino.dart`. Prefer neutral Flutter libraries when design widgets are unnecessary. Preserve this project's architecture and public contracts.

Resolve dependencies from each affected package root with `flutter pub get --no-example`. For a design migration, run `dart fix --apply --code=migrate_design_widgets` and review its output. After every code edit, run these commands sequentially from the affected package root:

```sh
dart fix --apply
dart format .
flutter analyze
```

Fix and format must finish before analysis or tests. Analyzer-only verification is the default. Run a focused test or build when requested or needed to prove a specific behavior change; choose the smallest useful check. Passing analysis does not prove runtime, provider, native linking, or integration behavior. Never suppress maintained-source diagnostics to obtain a pass. Preserve tool-owned generated files.

Existing web runners: `example`. When a run is requested, use the existing web development workflow with one explicitly selected target and port, then inspect it with Playwright MCP. An explicitly requested `flutter build web` is a compile check, separate from the development run. Do not add web targets merely to validate a migration.

Use a reachable physical Android device only when web is unsupported and device execution is requested. No emulator or simulator is authorized. This Linux VPS cannot execute native iOS/macOS builds or assume access to a phone attached to the Mac. Observe the global 500 MB download rule and preserve existing edits, credentials, caches, and running sessions. Do not push, publish, deploy, or run native builds without task authorization.

Use one handwritten class/widget per file; a StatefulWidget and its paired State may share a file. Apply SOLID without speculative abstractions. Keep UI, coordination, domain behavior, transport, persistence, and provider mechanics in their existing layers; use explicit types and correct async ownership/disposal. Do not impose another project’s state management or architecture.


## Coding Style & Naming Conventions

Use null-safe, idiomatic Dart and accept `dart format`'s two-space layout. Name files `snake_case.dart`, public types `UpperCamelCase`, members `lowerCamelCase`, and private declarations with a leading underscore. Existing public UI types use the `V` prefix, such as `VMessageInputWidget` and `VInputLanguage`; follow that convention for exported APIs. Prefer typed callbacks and small reusable widgets. Preserve backward compatibility unless a breaking change is intentional and documented.

## Testing Guidelines

Use `flutter_test`; name files `*_test.dart` and group tests by widget or behavior. Add widget tests for submission callbacks, typing/recording transitions, permissions, attachment limits, mentions, and disabled states when those paths change. The root test file is currently a placeholder and no coverage threshold is enforced, so meaningful behavior changes must add focused assertions. Use `flutter test --coverage` when coverage evidence is useful.

## Commit & Pull Request Guidelines

History favors short imperative subjects such as `Support Flutter V3.24`, `Fix update theme`, and `Update the example`; keep each commit focused and avoid vague multi-purpose messages. Pull requests should explain the user-visible change, compatibility impact, and validation performed; link relevant issues and include screenshots or recordings for UI changes. Update `CHANGELOG.md` and `pubspec.yaml` only when the change is release-facing.

## Security & Configuration

Never commit API keys, signing data, local paths, or credentials. Pass Google Maps keys and permission-sensitive behavior through application configuration, and verify denial and cancellation paths on affected platforms.

## Local package migration dependencies

The development overrides in `pubspec_overrides.yaml`, `example/pubspec_overrides.yaml` point to migrated sibling packages in the organized workspace. Keep the relative layout when developing this migration. Hosted releases may still expose legacy Material theme types. Before distributing a checkout independently, release compatible dependency versions and update its hosted constraints; do not publish local paths or force incompatible overrides.

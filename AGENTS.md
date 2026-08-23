# Repository Guidelines

## Project Structure & Module Organization

This repository is the `v_chat_input_ui` Flutter package. `lib/v_chat_input_ui.dart` is the public entry point; keep exported API additions explicit there. Implementation code lives in `lib/src/`, grouped into `input/` widgets, `recorder/`, `models/`, and shared `v_widgets/`. Package tests belong in `test/`. The `example/` directory is a standalone Flutter application with its own `lib/`, `test/`, and platform runners; use it for integration and visual checks. Do not commit generated `.dart_tool/`, `build/`, IDE, or plugin-registration files.

## Build, Test, and Development Commands

- `flutter pub get` resolves package dependencies.
- `dart format --output=none --set-exit-if-changed lib test example/lib example/test` verifies formatting; omit the flags to apply fixes.
- `flutter analyze` runs the `flutter_lints` rules configured in `analysis_options.yaml`.
- `flutter test` runs package tests after `flutter_test` is declared under root `dev_dependencies`.
- `cd example && flutter test` runs the example smoke tests.
- `cd example && flutter run` launches the example on a selected device for interaction and layout checks.

## Coding Style & Naming Conventions

Use null-safe, idiomatic Dart and accept `dart format`'s two-space layout. Name files `snake_case.dart`, public types `UpperCamelCase`, members `lowerCamelCase`, and private declarations with a leading underscore. Existing public UI types use the `V` prefix, such as `VMessageInputWidget` and `VInputLanguage`; follow that convention for exported APIs. Prefer typed callbacks and small reusable widgets. Preserve backward compatibility unless a breaking change is intentional and documented.

## Testing Guidelines

Use `flutter_test`; name files `*_test.dart` and group tests by widget or behavior. Add widget tests for submission callbacks, typing/recording transitions, permissions, attachment limits, mentions, and disabled states when those paths change. The root test file is currently a placeholder and no coverage threshold is enforced, so meaningful behavior changes must add focused assertions. Use `flutter test --coverage` when coverage evidence is useful.

## Commit & Pull Request Guidelines

History favors short imperative subjects such as `Support Flutter V3.24`, `Fix update theme`, and `Update the example`; keep each commit focused and avoid vague multi-purpose messages. Pull requests should explain the user-visible change, compatibility impact, and validation performed; link relevant issues and include screenshots or recordings for UI changes. Update `CHANGELOG.md` and `pubspec.yaml` only when the change is release-facing.

## Security & Configuration

Never commit API keys, signing data, local paths, or credentials. Pass Google Maps keys and permission-sensitive behavior through application configuration, and verify denial and cancellation paths on affected platforms.

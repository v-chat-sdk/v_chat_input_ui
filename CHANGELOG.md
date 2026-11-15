## 4.1.0 - 2026-11-04

- Add borrowed draft-controller synchronization, accepted-send handling, configurable mention height, and public picker access.
- Preserve external drafts and stop composer activity when messaging is unavailable.
- Restore mention queries across drafts and callback changes, using consumer theme emphasis.
- Require mention controller ^2.0.1 for safe disposal and multiline restored mentions.
- Serialize recording startup, submission, and shutdown to prevent late voice sends or recording after removal.

## 4.0.0 - 2026-11-04

- Require v_chat_mention_controller ^2.0.0, including debounce cancellation and callback cleanup on disposal.

- Require Flutter >=3.47.0 and Dart >=3.13.0 <4.0.0 for this SDK update.
- Refresh package and example dependency constraints to current stable releases as of 2026-11-04, subject to documented upstream compatibility constraints.
- Validate with Flutter 3.47.8 / Dart 3.13.7 using fix, format, static analysis, and package/example tests.
- Upgrade file_picker to 13.3.2, image_cropper to 13.0.0, and adaptive_dialog to 3.0.1.
- Enforce attachment limits for unknown-length files by streaming only until the limit is crossed.
- Keep cross_file at ^0.3.5+5 for file_picker compatibility; accept Cupertino icon font 1.x and 2.x for Chewie consumers.
- Update the Android example to AGP 9.1.1 / Gradle 9.3.1 for API 37, and add iOS permission descriptions.

## 3.4.2

- Add `singleLineHint` to keep a long composer placeholder on one line without limiting multiline messages.
- Keep the package compatible with newer allowed `file_picker` and `v_platform` releases.

## 3.4.1

- Lock the built-in camera picker capture orientation to portrait so the camera UI and preview stay correct when the chat is opened while the device is in landscape.
- Expose the camera picker config construction for testing via `VAppPick.buildCameraPickerConfig`.

## 3.4.0

- Add `includeSafeAreaForVAttachmentPanel` to `VMessageInputWidget` to control `SafeArea` wrapping for attachment panels (defaults to `true`).
- Center-align the composer row (`CrossAxisAlignment.center`) for more consistent vertical alignment of the input field and action buttons.
- Decouple the camera attachment from `enableCamera` for panel presentations so the panel camera action is available whenever configured; `enableCamera` now only gates the standalone camera launcher and recording paths.
- Keep location filtering for explicit attachment actions so `VLocationAttachmentAction` remains hidden when `googleMapsApiKey` is absent, and restore consistent filtering for the default panel.

## 3.3.0

- Make the built-in emoji picker react to live light/dark theme and locale changes.
- Add responsive picker sizing, adaptive emoji columns, an iOS emoji-size adjustment, remembered skin tones, localized search and empty states, and a useful initial category.
- Add `VEmojiPickerThemeData` for picker styling and `emojiPickerBuilder` for complete panel replacement.
- Add a public screenshot gallery covering the composer, inline attachments, custom recording UI, and emoji picker.

## 3.2.0

- Add typed Media, Camera, Files, Location, and consumer-owned attachment actions.
- Add adaptive action-sheet, modal bottom-sheet, and animated inline-tray presentations with configurable grid, horizontal, and wrap layouts.
- Add logical attachment-launcher placement, a composer panel controller, coordinated keyboard/emoji/attachment transitions, and system-Back handling for inline panels.
- Add attachment panel theming, localization and accessibility labels, responsive example controls, and a custom Poll action demonstration.
- Match the Send and Record controls to the composer's themed minimum height and expose `composerActionExtent` for sizing.
- Add live `VRecordingState` data and `recordingWidgetBuilder` for fully custom recording visuals while retaining package-owned recorder cleanup.
- Preserve the existing action sheet, `AttachEnumRes`, callbacks, picker limits, mentions, reply UI, draft state, and constructor defaults.

## 3.1.0

- Add accessible action labels and independent emoji, attachment, camera, and voice-recorder toggles.
- Honor `VInputTheme` extensions registered on `ThemeData` and interpolate theme values during transitions.
- Export all callback payload and typing-state types from the package entrypoint.
- Fix oversized media/file filtering so only accepted files reach submission callbacks.
- Fix recorder maximum-duration completion, picker busy-state cleanup, focus-node ownership, and stale mention-search results.
- Replace the counter example with an interactive chat-composer demo and document the package with a real screenshot.
- Upgrade `file_picker`, `image_cropper`, and `permission_handler` to their latest compatible releases.

## 3.0.1

- Declare the `cupertino_icons` dependency so consumers bundle its icon font.

## 3.0.0

- Require Flutter 3.44 and Dart 3.12.
- Upgrade direct dependencies to their latest compatible releases.
- Migrate file picking to the static API.
- Replace the incompatible Phosphor icon dependency with Material icons.
- Add package-level public API tests.

## 2.2.0

- Support Flutter 3.27.

## 2.0.1

- Support Flutter 3.24.

## 2.0.0

- Support Flutter 3.22.

## 1.3.0

- Upgrade dependencies.

## 1.2.2

- Update the assets package.

## 1.2.1

- Upgrade dependencies.

## 1.0.0

- Support Dart 3.

## 0.4.0

- Add full localization support.

## 0.3.0

- Add web support.

## 0.0.5

- Fix mention markup text.

## 0.0.4

- Add image compression.

## 0.0.3

- Add more customization options and iOS/macOS support.

## 0.0.2

- Add theming and localization.

## 0.0.1

- Initial release.

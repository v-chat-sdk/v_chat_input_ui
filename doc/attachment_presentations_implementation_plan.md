# Attachment Presentations Implementation Plan

Status: implementation-ready plan

Package: `v_chat_input_ui`

Primary widget: `VMessageInputWidget`

Reference behavior: an attachment tray that expands directly below the composer and swaps cleanly with the software keyboard

## 1. Outcome

Add one shared, typed attachment-action system that can be rendered in three built-in presentation styles:

1. `VAttachmentPresentation.adaptiveActionSheet`
   - Preserves the package's existing default behavior.
   - Presents actions as a dismissible action sheet.
2. `VAttachmentPresentation.modalBottomSheet`
   - Presents the same actions in a modal grid/list above the current route.
3. `VAttachmentPresentation.inlineTray`
   - Expands the actions directly beneath the composer.
   - Treats the software keyboard, emoji picker, and attachment tray as mutually exclusive bottom surfaces.

Consumers can override the built-in renderer with a typed custom presentation builder without changing action dispatch.

The implementation must preserve the current constructor defaults, callbacks, attachment size filtering, permissions, picker behavior, mention handling, recording, and typing notifications unless the consumer opts into a new presentation or layout.

## 2. Confirmed product decisions

- Implement all three built-in presentation values in the public API.
- Keep `adaptiveActionSheet` as the default so an existing `VMessageInputWidget` keeps its current behavior.
- Implement `inlineTray` as the reference-quality experience shown in the supplied UI.
- Keep presentation, action content, action layout, and launcher placement as independent settings.
- Keep Poll application-owned. The package supplies a generic custom action; it does not define poll models, validation, persistence, or transport.
- Preserve the current media, file, camera, and location submission callbacks.
- Preserve `onAttachIconPress` as a legacy override in this release. Document its precedence and provide a migration path; do not remove it.
- Add no dependency unless implementation proves that Flutter SDK primitives cannot satisfy a requirement.
- Do not bump `pubspec.yaml` during implementation unless a release version is explicitly chosen. Record the feature under an `Unreleased` changelog section.

## 3. Non-goals

- Uploading attachments or sending network requests.
- Creating or submitting polls.
- Changing file-size limits or picker output models.
- Owning the host chat list, message scrolling, or message transport.
- Replacing the existing emoji picker package.
- Redesigning the recorder UI.
- Removing or renaming existing public constructor parameters.

## 4. Public API design

### 4.1 Presentation

Add `lib/src/input/attachments/v_attachment_presentation.dart`:

```dart
enum VAttachmentPresentation {
  adaptiveActionSheet,
  modalBottomSheet,
  inlineTray,
}
```

Add to `VMessageInputWidget`:

```dart
final VAttachmentPresentation attachmentPresentation;

// Backward-compatible default.
this.attachmentPresentation =
    VAttachmentPresentation.adaptiveActionSheet,
```

### 4.2 Attachment actions

Add `lib/src/input/attachments/v_attachment_action.dart` with a sealed, immutable action hierarchy. Factory constructors keep consumer code concise while allowing exhaustive internal dispatch.

```dart
sealed class VAttachmentAction {
  const VAttachmentAction({
    this.label,
    this.icon,
    this.semanticLabel,
  });

  final String? label;
  final Widget? icon;
  final String? semanticLabel;

  const factory VAttachmentAction.media({...});
  const factory VAttachmentAction.camera({...});
  const factory VAttachmentAction.files({...});
  const factory VAttachmentAction.location({...});
  const factory VAttachmentAction.custom({
    required String id,
    required String label,
    required Widget icon,
    required FutureOr<void> Function(BuildContext context) onPressed,
    String? semanticLabel,
  });
}
```

Design rules:

- Built-in actions delegate to the existing media, camera, file, and location handlers.
- Built-in labels and icons resolve from `VInputLanguage` and `VInputTheme` when not overridden.
- Custom action IDs must be non-empty and unique within the resolved list.
- Custom callbacks own their domain behavior and errors.
- An action closes its presentation before opening a picker, route, or custom flow.
- Prevent duplicate taps while an action is being dispatched.
- Preserve draft text, mention markup, selection, reply UI, and typing state across action dispatch.

Add to `VMessageInputWidget`:

```dart
final List<VAttachmentAction>? attachmentActions;
```

Resolution behavior:

- `null` with `adaptiveActionSheet`: preserve the current Media, Files, and optional Location actions exactly.
- `null` with `modalBottomSheet` or `inlineTray`: resolve Media, optional Camera, Files, and optional Location in that order.
- An explicit list controls action order and visibility.
- A Camera action is omitted when camera support is disabled or unavailable on the platform.
- A Location action is omitted when `googleMapsApiKey` is absent.
- `enableAttachments` remains the master switch for the launcher and all presentations.
- `enableCamera` remains the capability switch for both the standalone camera launcher and a Camera attachment action.

### 4.3 Launcher placement

Add `lib/src/input/attachments/v_attachment_launcher_placement.dart`:

```dart
enum VAttachmentLauncherPlacement {
  insideInput,
  leadingOutside,
  trailingOutside,
}
```

Add to `VMessageInputWidget`:

```dart
final VAttachmentLauncherPlacement attachmentLauncherPlacement;
final bool showCameraLauncher;

this.attachmentLauncherPlacement =
    VAttachmentLauncherPlacement.insideInput,
this.showCameraLauncher = true,
```

Rules:

- `insideInput` preserves the current paperclip placement.
- `leadingOutside` implements the supplied UI and respects `Directionality`; it is left in LTR and right in RTL.
- `trailingOutside` provides the symmetric alternative.
- Launcher placement changes only layout. It does not choose presentation or actions.
- While the inline tray is open, the launcher uses a keyboard icon and an appropriate semantic label.
- The standalone camera shortcut is visible only when both `enableCamera` and `showCameraLauncher` are true.
- A Camera item can also appear in the attachment action list. Showing both is valid and matches the supplied UI; set `showCameraLauncher` to false when Camera should exist only in the panel.

### 4.4 Panel layout

Add `lib/src/input/attachments/v_attachment_panel_layout.dart`:

```dart
enum VAttachmentPanelLayout {
  grid,
  horizontalList,
  wrap,
}
```

Add to `VMessageInputWidget`:

```dart
final VAttachmentPanelLayout? attachmentPanelLayout;

this.attachmentPanelLayout,
```

Recommended defaults:

- `adaptiveActionSheet`: renderer-controlled list.
- `modalBottomSheet`: `grid`.
- `inlineTray`: `horizontalList`.

A null value selects the presentation-specific default above. An explicit value overrides it where the renderer supports panel layouts.

The built-in panel must remain usable with narrow widths, text scaling, RTL, and more actions than fit on screen.

### 4.5 Custom panel builder

Add a builder that overrides the panel body for `inlineTray` and `modalBottomSheet`. It receives already-resolved actions plus a constrained controller:

```dart
typedef VAttachmentPanelBuilder = Widget Function(
  BuildContext context,
  List<VAttachmentAction> actions,
  VAttachmentPresentationController controller,
);

final VAttachmentPanelBuilder? attachmentPanelBuilder;
```

The controller exposes only safe presentation operations:

```dart
abstract interface class VAttachmentPresentationController {
  bool get isOpen;
  Future<void> select(VAttachmentAction action);
  void close();
  void showKeyboard();
}
```

The builder must not receive private picker implementations or mutable composer internals. `adaptiveActionSheet` has no arbitrary widget body, so it continues to map typed actions to native/adaptive sheet actions. A consumer that needs a completely custom presentation mechanism can continue using the existing `onAttachIconPress` override in this release.

### 4.6 Composer controller

Add an optional `VMessageInputController` so the host chat screen can close panels when its message list is tapped or scrolled:

```dart
enum VComposerPanel { none, emoji, attachments }

class VMessageInputController extends ChangeNotifier {
  VComposerPanel get activePanel;
  void showAttachments();
  void showEmoji();
  void showKeyboard();
  void closePanel();
}
```

`VMessageInputWidget` owns and disposes an internal controller when none is supplied. It attaches to, detaches from, but never disposes a consumer-owned controller.

Add to `VMessageInputWidget`:

```dart
final VMessageInputController? controller;

this.controller,
```

## 5. Internal state model

Do not add a manually synchronized `isKeyboardOpen` boolean. The operating system controls the IME, a focused field can use a hardware keyboard with zero bottom inset, and mobile system Back can hide the IME independently.

Maintain these independent internal concepts:

```dart
VComposerPanel _activePanel;       // none, emoji, attachments
VComposerPanel? _pendingPanel;     // waiting for mobile IME dismissal
bool _hasDraftText;                // drives Send vs Record UI
bool _isRecording;                 // drives recorder UI
RoomTypingEnum _reportedActivity;  // consumer notification state
int _surfaceTransitionGeneration;  // invalidates stale async transitions
```

Sources of truth:

- `FocusNode` owns input focus.
- `MediaQuery.viewInsetsOf(context).bottom` observes mobile keyboard geometry for transition/layout purposes only.
- The text controller owns the draft, cursor, selection, and mention markup.
- `_hasDraftText` drives send-button visibility independently from focus or remote typing notifications.
- `_reportedActivity` drives `onTypingChange` independently from attachment/emoji presentation.

This separation removes the current coupling where `RoomTypingEnum` also controls whether Send or Record is visible.

## 6. Required transition contract

| Starting state | User/system event | Required result |
|---|---|---|
| Keyboard visible | Tap attachment launcher | Clear stale transitions, request Attachments, unfocus input, wait for mobile inset to close, then show tray |
| Keyboard closed | Tap attachment launcher | Show tray immediately |
| Attachment tray open | Tap keyboard launcher | Close tray, then request input focus after the layout frame |
| Attachment tray open | Tap text field | Close tray and request/retain text-field focus in the same interaction |
| Attachment tray open | Tap emoji | Replace tray with emoji; never show both |
| Emoji open | Tap attachment launcher | Replace emoji with attachments; keep mobile IME dismissed |
| Any panel open | External `FocusNode.requestFocus()` | Close the panel and allow keyboard presentation |
| Any panel open | System Back | Close the panel only; do not pop the chat route |
| Keyboard visible | System Back | Let the platform hide the keyboard; do not open a panel |
| Tray/sheet open | Select built-in action | Close presentation, preserve draft, then run permission/picker/location flow |
| Tray/sheet open | Select custom action | Close presentation, preserve draft, then invoke callback once |
| Picker canceled | Return to composer | Preserve draft; keep keyboard closed unless consumer explicitly requests it |
| Attachments disabled while open | Widget update | Close pending/open attachment presentation safely |
| Closed-chat widget appears | Widget update | Close panels, cancel pending transitions, unfocus input, reset activity consistently |
| Widget/controller disposed | Lifecycle | Invalidate pending work; never call callbacks or `setState` after disposal |

### Transition implementation rules

- Remove the current fixed 50 ms emoji delay.
- Use synchronous intent changes plus post-frame callbacks where focus must be restored.
- Use `_surfaceTransitionGeneration` so the latest user intent wins during rapid attachment/input/emoji taps.
- On mobile, do not render the inline tray while a positive keyboard inset is still occupying the bottom area unless the transition deliberately reserves an equivalent height.
- On desktop/web or a hardware-keyboard setup with zero inset, open the inline tray immediately.
- Do not call private/system text-input channels to hide the keyboard while retaining focus. Use `FocusNode.unfocus()` and later `requestFocus()`.
- The input's own `onTap` callback closes panels without wrapping the text field in a competing gesture detector.
- Keep focus listeners as a second path for consumer-driven/external focus requests.

## 7. Rendering architecture

### 7.1 Shared action resolver and dispatcher

Add private collaborators under `lib/src/input/attachments/`:

- `attachment_action_resolver.dart`
  - Resolves defaults, labels, icons, platform availability, and consumer overrides.
- `attachment_action_dispatcher.dart`
  - Routes built-in actions to existing package handlers and custom actions to their callback.
  - Enforces single-flight selection.
- `attachment_action_tile.dart`
  - Shared accessible tile used by inline and modal renderers.

Keep media/file size validation and picker methods in their existing implementations; presenters must not duplicate them.

### 7.2 Adaptive action sheet

- Refactor `VAppAlert.showModalSheet` to accept the typed resolved action list through an adapter.
- Preserve title, cancellation, dismissibility, action order, existing callbacks, and existing default appearance.
- If a custom icon is not representable by the underlying action-sheet API, retain the label and use a documented standard fallback icon rather than rejecting the action.
- Close/unfocus before launching the selected action.

### 7.3 Modal bottom sheet

Add `v_attachment_modal_sheet.dart`:

- Use Flutter's modal bottom-sheet API and `SafeArea`.
- Render `grid`, `horizontalList`, or `wrap` according to configuration.
- Constrain height and allow scrolling for large action sets or large text scale.
- Respect Material/Cupertino host themes through package theme values rather than hard-coded colors.
- Dismiss on barrier tap, drag, system Back, action selection, and controller close.
- Return a selected action to the shared dispatcher; do not run pickers from inside the modal route before it closes.

### 7.4 Inline tray

Add `v_attachment_inline_tray.dart` beneath the primary composer row:

- Use `AnimatedSize` plus `AnimatedSwitcher` or equivalent Flutter SDK primitives.
- Keep the composer text field mounted throughout transitions.
- Use `SafeArea(top: false)` for the bottom edge.
- Do not use an overlay or nested modal route.
- Do not show the tray and `EmojiKeyboard` simultaneously.
- Keep the launcher visible and replace its open icon with the keyboard icon while active.
- Prefer a `Column(mainAxisSize: MainAxisSize.min)` composer structure. Reassess the current outer `SingleChildScrollView`; do not let a dynamic tray silently create a nested scrolling composer.
- Optionally cache the last positive keyboard height only for animation continuity. Never require a previous keyboard measurement; use configured panel constraints when no measurement exists.

## 8. Input-row refactor

Refactor `MessageTextFiled` without exposing it publicly:

- Correct the internal filename/class spelling only if it can be done without public impact; otherwise defer the rename to avoid unrelated churn.
- Add typed callbacks for input tap and presentation launcher actions.
- Extract reusable internal action-button widgets so inside/outside placements share semantics and constraints.
- Build the composer row in `VMessageInputWidget`, where leading/trailing outside launchers and the text-field container can be ordered correctly.
- Preserve current action order and spacing when all new options use defaults.
- Preserve multiline alignment.
- Keep minimum interactive targets at least 44x44 logical pixels, preferably the current 40 minimum plus sufficient surrounding layout or a revised 48 target.
- Keep camera/send/record visibility independent from panel state and draft state.

## 9. Theme and localization

### 9.1 Theme

Add an immutable nested `VAttachmentThemeData` to `VInputTheme` rather than adding many unrelated top-level fields:

```dart
class VAttachmentThemeData {
  final Decoration? panelDecoration;
  final Decoration? actionDecoration;
  final Decoration? selectedActionDecoration;
  final TextStyle? labelStyle;
  final EdgeInsets panelPadding;
  final EdgeInsets actionPadding;
  final double spacing;
  final double runSpacing;
  final double actionExtent;
  final Widget? launcherOpenIcon;
  final Widget? launcherKeyboardIcon;
}
```

Requirements:

- Provide light and dark defaults.
- Implement `copyWith`, equality where appropriate, and interpolation for animatable values.
- Preserve existing `fileIcon` as the fallback open launcher icon.
- Avoid hard-coded colors from the reference image; consumers can reproduce them through action/icon overrides and theme data.

### 9.2 Language

Extend `VInputLanguage` with backward-compatible defaults for:

- Camera action label.
- Photos/media action label if a distinct tray label is needed.
- Documents/files action label if a distinct tray label is needed.
- Attachment panel semantic label/title.
- Show attachment actions tooltip.
- Return to keyboard tooltip.
- Close attachment actions tooltip.

Reuse existing `media`, `files`, `location`, and accessibility labels where their meaning already matches.

## 10. Back handling and host coordination

- Use route-aware back handling (`PopScope` or a route-local-history entry chosen after a focused spike) so an active/pending panel consumes Back before the chat route pops.
- Do not intercept Back when no custom panel is active; the platform remains responsible for keyboard dismissal and route navigation.
- Expose `VMessageInputController.closePanel()` for message-list taps, drag-to-dismiss behavior, route changes, and host lifecycle events.
- Expose an optional `ValueChanged<VComposerPanel>` callback only if the controller's notification is insufficient for common hosts. Avoid two redundant public observation APIs.
- Document that `Scaffold.resizeToAvoidBottomInset` should remain enabled for the standard inline behavior.

## 11. Backward compatibility and precedence

Constructor behavior precedence:

1. `enableAttachments == false`: no launcher or presentation.
2. Existing `onAttachIconPress != null`: run the legacy override exactly as today; new built-in presentation settings are bypassed and this precedence is documented.
3. Otherwise switch on `attachmentPresentation`.
4. Within `inlineTray` or `modalBottomSheet`, use `attachmentPanelBuilder` when supplied; otherwise use the built-in panel body.

Compatibility assertions:

- The default constructor renders the same launcher location and opens the same action sheet actions as version 3.1.0.
- Existing `AttachEnumRes` remains exported and unchanged because it is part of `onAttachIconPress`.
- Existing callbacks retain their signatures and submission payloads.
- Existing `enableCamera`, `enableAttachments`, `googleMapsApiKey`, and `maxMediaSize` behavior remains authoritative.
- No existing consumer must create a `VMessageInputController`.
- No existing consumer must define `attachmentActions`.
- Additions are source-compatible and do not require a major version solely for this feature.

After the new API is proven, a later release may deprecate `onAttachIconPress` in favor of custom actions/builders. Do not deprecate it in the first implementation unless migration documentation and tests are complete.

## 12. Accessibility, internationalization, and responsive requirements

- Every launcher and action must have a tooltip/semantic label.
- Expose expanded/collapsed semantics on the attachment launcher where Flutter semantics support it.
- Preserve logical leading/trailing placement in RTL.
- Preserve action order under RTL while allowing Flutter's direction-aware layout to mirror naturally.
- Support text scale without clipping labels; allow two lines or scrolling where necessary.
- Support screen-reader traversal from composer controls into the inline tray.
- Do not automatically move accessibility focus unless required to announce the newly opened panel.
- Respect high-contrast theme choices supplied through `ThemeData`/`VInputTheme`.
- Avoid color as the only indication of action identity or open state.

## 13. Platform behavior matrix

| Platform | Inline tray keyboard behavior | Modal/action-sheet behavior |
|---|---|---|
| Android phone/tablet | Unfocus and wait/synchronize with IME inset; Back closes tray first | Unfocus before presenting; Android Back dismisses presentation |
| iPhone/iPad touch keyboard | Unfocus and synchronize with inset; keyboard launcher restores focus | Unfocus before presenting; dismissal preserves draft |
| iPad/Android hardware keyboard | Zero inset opens tray immediately; focus policy remains configurable/internal | Present normally without relying on inset |
| Web | Open inline immediately; avoid pretending a zero inset means no focus | Use responsive modal constraints |
| Windows/macOS | Open inline immediately and preserve practical hardware-keyboard UX | Use responsive modal constraints |

The implementation must not infer platform support solely from screen size.

## 14. Implementation phases

### Phase 0: Baseline and safety

1. Re-read the current dirty-tree diff for every relevant file.
2. Treat current working-tree content as the implementation baseline; do not reset, stash, or overwrite it.
3. Run the current package and example tests before edits and record any pre-existing failures.
4. Capture the current default composer and attachment action sheet behavior.

Exit criteria:

- Existing behavior and failures are documented.
- No unrelated working-tree file is changed.

### Phase 1: Public models and exports

1. Add presentation, launcher placement, panel layout, action, controller, and builder types.
2. Add constructor parameters with compatibility-preserving defaults.
3. Export all intended consumer-facing types explicitly from `lib/v_chat_input_ui.dart`.
4. Add API/model tests before wiring presentation behavior.

Exit criteria:

- Package compiles.
- Public API tests prove defaults and exports.
- Existing constructor call sites compile unchanged.

### Phase 2: Separate composer state concerns

1. Split draft presence, recording, reported activity, focus, and active panel state.
2. Replace `_isEmojiShowing` with the shared panel state.
3. Remove the fixed emoji delay.
4. Add generation-safe show/close/show-keyboard transitions.
5. Add input-tap and external-focus coordination.
6. Close panels on stop-chat, disable, widget update, and disposal paths.

Exit criteria:

- Emoji behavior remains correct.
- Rapid input/emoji/attachment intent cannot leave two surfaces active.
- Send/record UI is correct with a non-empty draft regardless of focus.

### Phase 3: Shared actions and legacy presenter

1. Implement action resolution and validation.
2. Move existing media/file/location/camera dispatch behind the shared dispatcher.
3. Adapt the current action sheet to resolved actions.
4. Preserve legacy `onAttachIconPress` precedence.

Exit criteria:

- Default behavior matches the current package.
- Existing size filtering and callbacks remain covered.
- Custom actions dispatch once after the presentation closes.

### Phase 4: Modal bottom sheet

1. Implement the modal renderer and shared action tile.
2. Support all panel layouts and large action sets.
3. Add SafeArea, scrolling, barrier/back dismissal, and async action guards.

Exit criteria:

- Modal presentation works with built-in and custom actions.
- Cancel/dismiss paths do not mutate the draft or invoke an action.

### Phase 5: Inline tray and launcher placement

1. Refactor the composer row to support inside/leading/trailing launchers.
2. Insert the animated inline surface below the row.
3. Coordinate keyboard inset, focus, input tap, emoji, and system Back.
4. Implement keyboard-icon replacement while the tray is open.
5. Add controller-driven close/show behavior.

Exit criteria:

- The supplied UI interaction is reproducible without an app-side overlay.
- Keyboard and custom panels never remain simultaneously visible after transitions settle.
- Draft, cursor, mentions, reply UI, and Send state survive all transitions.

### Phase 6: Theme, language, accessibility, and responsiveness

1. Add attachment theme data with light/dark defaults and interpolation.
2. Add localized labels and accessibility text.
3. Validate RTL, text scaling, narrow width, many actions, and semantic traversal.

Exit criteria:

- No hard-coded reference-app branding is required.
- All actions remain reachable and labeled across supported layouts.

### Phase 7: Example and documentation

1. Update the example to switch among all three presentations.
2. Demonstrate inside and leading-outside launcher placement.
3. Add a custom Poll action that shows a local placeholder/snackbar only.
4. Document controller use for message-list taps/scrolls.
5. Add README migration and API examples.
6. Add light/dark screenshots of the inline tray.
7. Add an `Unreleased` changelog entry; do not change the package version without release direction.

Exit criteria:

- Every public option has a runnable example.
- Documentation clearly separates presentation from attachment domain behavior.

### Phase 8: Full validation and diff review

1. Run format, static analysis, package tests, and example tests.
2. Build representative mobile, web, and desktop targets.
3. Perform manual keyboard-transition checks on Android and iOS.
4. Review the complete diff for unrelated or generated changes.
5. Report local-only results. Do not commit, push, publish, or deploy without explicit authorization.

## 15. Test plan

### 15.1 Public API and model tests

- All three `VAttachmentPresentation` values are exported.
- Launcher placement and panel layout values are exported.
- Built-in action factories create the correct subtype.
- Custom action enforces ID, label, icon, and callback requirements.
- Duplicate custom IDs are rejected or deterministically handled.
- Theme defaults, `copyWith`, and `lerp` preserve all new fields.
- Language defaults remain usable and consumer overrides work.

### 15.2 Compatibility tests

- A widget with no new parameters renders the existing inside-input launcher.
- The default launcher opens Media, Files, and optional Location through the existing action sheet.
- Existing `onAttachIconPress` still bypasses built-in presentation.
- Existing action enable flags hide the same controls.
- `showCameraLauncher: false` hides only the standalone shortcut while an enabled Camera panel action remains available.
- Camera can intentionally remain available both as a standalone shortcut and as a panel action.
- Existing media/file size filtering remains unchanged.
- Existing callback payload types remain exported.

### 15.3 Presentation tests

For each built-in presentation:

- Opens from the launcher.
- Renders actions in resolved order.
- Dispatches media, camera, files, location, and custom actions correctly.
- Closes before callback/picker dispatch.
- Dismisses without dispatch on cancel/barrier/back where applicable.
- Prevents duplicate dispatch during an async action.
- Safely handles widget disposal while an action is pending.

### 15.4 Keyboard and focus tests

- Opening inline tray from a focused input removes focus on mobile behavior.
- Tapping the input while the tray is open closes it and restores focus.
- Tapping the keyboard launcher closes the tray and restores focus.
- Opening attachments while emoji is open replaces emoji.
- Opening emoji while attachments are open replaces attachments.
- External focus requests close an active panel.
- Rapid launcher/input/emoji taps obey last-intent-wins.
- Fake positive `viewInsets.bottom` delays/synchronizes inline presentation correctly.
- Zero inset permits immediate presentation for hardware keyboard/web/desktop behavior.
- System Back closes a panel without popping the route.
- System Back with no panel is not intercepted.
- A non-empty draft keeps Send visible while panels open/close.
- Draft text, markup, selection, and reply widget survive every transition.

### 15.5 Layout and accessibility tests

- Leading/trailing placement follows LTR and RTL directionality.
- Grid, horizontal list, and wrap render without overflow at narrow widths.
- Additional actions remain scrollable/reachable.
- Large text scale does not clip controls or labels.
- Launcher and every action expose expected tooltips/semantics.
- Open/closed launcher state is announced.
- Inline tray respects bottom SafeArea.

### 15.6 Example tests

- Example initially renders the compatibility/default presentation.
- Presentation selector switches among all three modes.
- Inline tray opens and returns to keyboard mode.
- Custom Poll action produces its local demonstration result.
- Light/dark theme switching styles the new panel.

## 16. Validation commands

Run from the package root unless noted:

```sh
flutter pub get
dart format lib test example/lib example/test
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
(cd example && flutter test)
(cd example && flutter build web)
(cd example && flutter build apk --debug)
(cd example && flutter build ios --simulator --no-codesign)
(cd example && flutter build macos)
```

Manual device/simulator checks are mandatory because widget tests cannot prove real IME animation and platform Back behavior:

- Android portrait and landscape: keyboard-to-tray, tray-to-keyboard, Back, picker cancel.
- iOS portrait and landscape: keyboard-to-tray, tray-to-keyboard, dismissal, safe area.
- Web/desktop with hardware keyboard: focus preservation and responsive panel layout.
- At least one RTL locale and increased system text scale.

Platform builds may be narrowed only when an unavailable local toolchain is reported explicitly; do not claim unrun targets as validated.

## 17. File-level implementation map

Expected new files:

- `lib/src/input/attachments/v_attachment_action.dart`
- `lib/src/input/attachments/v_attachment_presentation.dart`
- `lib/src/input/attachments/v_attachment_launcher_placement.dart`
- `lib/src/input/attachments/v_attachment_panel_layout.dart`
- `lib/src/input/attachments/v_attachment_theme_data.dart`
- `lib/src/input/attachments/v_message_input_controller.dart`
- `lib/src/input/attachments/attachment_action_resolver.dart`
- `lib/src/input/attachments/attachment_action_dispatcher.dart`
- `lib/src/input/attachments/attachment_action_tile.dart`
- `lib/src/input/attachments/v_attachment_inline_tray.dart`
- `lib/src/input/attachments/v_attachment_modal_sheet.dart`
- `test/attachment_presentations_test.dart`
- `test/composer_surface_state_test.dart`

Expected modified files:

- `lib/src/input/message_input_widget.dart`
- `lib/src/input/widgets/message_text_filed.dart`
- `lib/src/input/widgets/emoji_keyborad.dart`
- `lib/src/models/v_input_language.dart`
- `lib/src/models/v_input_theme.dart`
- `lib/src/models/models.dart` if attachment model exports remain routed through it
- `lib/src/v_widgets/v_app_alert.dart`
- `lib/v_chat_input_ui.dart`
- `test/v_chat_input_ui_test.dart`
- `example/lib/main.dart`
- `example/test/widget_test.dart`
- `README.md`
- `CHANGELOG.md`

Do not modify platform runner files unless a build exposes a feature-specific requirement. This feature should not require new native permissions beyond the package's existing camera/media/location behavior.

## 18. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Keyboard and tray briefly stack during IME animation | Pending-panel state driven by inset changes; generation-safe last intent; manual device validation |
| Rapid taps reopen a stale surface | Remove fixed delays and invalidate stale transitions with a generation counter |
| Draft Send button disappears when focus changes | Separate `_hasDraftText` from reported typing/recording activity |
| Back pops the chat route instead of closing tray | Route-aware panel back handling with focused Android/iOS tests |
| Camera appears both in the composer row and tray unexpectedly | Keep this supported because it matches the reference UI, but expose `showCameraLauncher` so consumers can deliberately remove the standalone shortcut; cover both configurations with tests |
| New action model breaks legacy callback | Keep `AttachEnumRes` and `onAttachIconPress` unchanged with documented precedence |
| Arbitrary custom icon cannot render in adaptive action sheet | Use a standard fallback icon in that renderer; preserve full custom widgets in modal/inline renderers |
| Large action sets overflow | Renderer-specific scrolling, constraints, wrap/grid tests, and text-scale tests |
| Package tries to manage host message-list gestures | Expose controller operations; do not install global gesture interception |
| Dirty checkout changes are overwritten | Treat current files as authoritative, inspect overlaps before each edit, never reset/stash unrelated work |
| Generated platform files change during validation | Review and exclude generated changes; do not commit them |

## 19. Definition of done

The feature is complete only when:

- All three built-in presentations use the same typed action list and dispatcher.
- Default construction remains behaviorally compatible with the existing package.
- The target leading-outside launcher plus inline tray is reproducible with public API only.
- The keyboard icon, input tap, emoji switch, system Back, and external controller transitions behave deterministically.
- Keyboard, emoji, and inline attachments never remain active together after a transition settles.
- Built-in and custom actions preserve drafts and dispatch exactly once.
- Theme, localization, RTL, text scale, accessibility, and responsive requirements are covered.
- Package and example tests pass.
- Required platform builds and real/simulated IME checks are reported with exact evidence.
- README, example, screenshots, and changelog describe the feature.
- The final diff contains no unrelated, generated, secret, commit, push, publish, or deployment changes.

## 20. Questions

No blocking question remains for implementation. The plan assumes all three presentations ship together, `adaptiveActionSheet` remains the compatibility default, and Poll is demonstrated as a consumer-owned custom action. If product scope later prefers a smaller first release, the phases allow `inlineTray` to ship first while keeping the same public action model.

## 21. Flutter references

- Focus removal: <https://api.flutter.dev/flutter/widgets/FocusNode/unfocus.html>
- Focus restoration: <https://api.flutter.dev/flutter/widgets/FocusNode/requestFocus.html>
- Keyboard geometry: <https://api.flutter.dev/flutter/widgets/MediaQueryData/viewInsets.html>
- Cupertino input taps: <https://api.flutter.dev/flutter/cupertino/CupertinoTextField/onTap.html>
- Route-aware Back handling: <https://api.flutter.dev/flutter/widgets/PopScope-class.html>

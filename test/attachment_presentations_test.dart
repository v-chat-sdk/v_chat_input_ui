// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_chat_input_ui/src/input/widgets/message_text_filed.dart';
import 'package:v_chat_input_ui/v_chat_input_ui.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  group('public attachment API', () {
    test('exports presentation, placement, layout, and panel states', () {
      expect(VAttachmentPresentation.values, [
        VAttachmentPresentation.adaptiveActionSheet,
        VAttachmentPresentation.modalBottomSheet,
        VAttachmentPresentation.inlineTray,
      ]);
      expect(VAttachmentLauncherPlacement.values, [
        VAttachmentLauncherPlacement.insideInput,
        VAttachmentLauncherPlacement.leadingOutside,
        VAttachmentLauncherPlacement.trailingOutside,
      ]);
      expect(VAttachmentPanelLayout.values, [
        VAttachmentPanelLayout.grid,
        VAttachmentPanelLayout.horizontalList,
        VAttachmentPanelLayout.wrap,
      ]);
      expect(VComposerPanel.values, [
        VComposerPanel.none,
        VComposerPanel.emoji,
        VComposerPanel.attachments,
      ]);
    });

    test('creates typed built-in and custom actions', () {
      const media = VAttachmentAction.media();
      const camera = VAttachmentAction.camera();
      const files = VAttachmentAction.files();
      const location = VAttachmentAction.location();
      final custom = VAttachmentAction.custom(
        id: 'poll',
        label: 'Poll',
        icon: const Icon(Icons.poll_outlined),
        onPressed: (_) {},
      );

      expect(media, isA<VMediaAttachmentAction>());
      expect(camera, isA<VCameraAttachmentAction>());
      expect(files, isA<VFilesAttachmentAction>());
      expect(location, isA<VLocationAttachmentAction>());
      expect(custom, isA<VCustomAttachmentAction>());
      expect(
        [media.id, camera.id, files.id, location.id, custom.id],
        ['media', 'camera', 'files', 'location', 'poll'],
      );
    });

    test('retains backward-compatible composer defaults', () {
      final widget = _composer();

      expect(
        widget.attachmentPresentation,
        VAttachmentPresentation.adaptiveActionSheet,
      );
      expect(
        widget.attachmentLauncherPlacement,
        VAttachmentLauncherPlacement.insideInput,
      );
      expect(widget.attachmentActions, isNull);
      expect(widget.attachmentPanelLayout, isNull);
      expect(widget.showCameraLauncher, isTrue);
      expect(widget.enableAttachments, isTrue);
    });

    test('provides attachment language and theme customization', () {
      const language = VInputLanguage(
        camera: 'Take photo',
        attachmentButtonLabel: 'Legacy attachment label',
        openAttachmentsButtonLabel: 'Open actions',
        attachmentPanelLabel: 'Share something',
        returnToKeyboardButtonLabel: 'Keyboard',
        closeAttachmentPanelButtonLabel: 'Close actions',
      );
      const start = VAttachmentThemeData.light(spacing: 4, actionExtent: 64);
      const end = VAttachmentThemeData.dark(spacing: 20, actionExtent: 96);
      final midpoint = start.lerp(end, 0.5);
      final copied = start.copyWith(spacing: 8);

      expect(language.camera, 'Take photo');
      expect(language.openAttachmentsButtonLabel, 'Open actions');
      expect(language.attachmentPanelLabel, 'Share something');
      expect(midpoint.spacing, 12);
      expect(midpoint.actionExtent, 80);
      expect(copied.spacing, 8);
      expect(copied.actionExtent, 64);
    });

    test('an unattached controller is safe and starts closed', () {
      final controller = VMessageInputController();

      expect(controller.activePanel, VComposerPanel.none);
      controller
        ..showAttachments()
        ..showEmoji()
        ..showKeyboard()
        ..closePanel();
      expect(controller.activePanel, VComposerPanel.none);
      controller.dispose();
    });
  });

  group('attachment presentations', () {
    for (final presentation in VAttachmentPresentation.values) {
      testWidgets('${presentation.name} opens and dispatches a custom action', (
        tester,
      ) async {
        var pollCount = 0;
        await tester.pumpWidget(
          _ComposerHost(
            attachmentPresentation: presentation,
            attachmentActions: [
              VAttachmentAction.custom(
                id: 'poll',
                label: 'Poll',
                icon: const Icon(Icons.poll_outlined),
                onPressed: (_) => pollCount++,
              ),
            ],
          ),
        );

        await tester.tap(find.byTooltip('Add attachment'));
        await tester.pumpAndSettle();
        expect(find.text('Poll'), findsOneWidget);

        await tester.tap(find.text('Poll'));
        await tester.pumpAndSettle();

        expect(pollCount, 1);
        expect(find.text('Poll'), findsNothing);
      });
    }

    testWidgets('legacy attachment callback overrides the new presenter', (
      tester,
    ) async {
      var legacyCalls = 0;
      final controller = VMessageInputController();
      await tester.pumpWidget(
        _ComposerHost(
          controller: controller,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [_pollAction()],
          onAttachIconPress: () async {
            legacyCalls++;
            return null;
          },
        ),
      );

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();

      expect(legacyCalls, 1);
      expect(find.text('Poll'), findsNothing);
      expect(controller.activePanel, VComposerPanel.none);
    });

    testWidgets('default action sheet preserves Media and Files actions', (
      tester,
    ) async {
      await tester.pumpWidget(const _ComposerHost(enableCamera: false));

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();

      expect(find.text('Media'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Camera'), findsNothing);
      expect(find.text('Location'), findsNothing);
    });

    testWidgets(
      'explicit actions retain order and filter unavailable actions',
      (tester) async {
        await tester.pumpWidget(
          _ComposerHost(
            enableCamera: false,
            attachmentPresentation: VAttachmentPresentation.inlineTray,
            attachmentActions: [
              _pollAction(),
              const VAttachmentAction.location(),
              const VAttachmentAction.files(label: 'Document'),
              const VAttachmentAction.camera(),
              const VAttachmentAction.media(label: 'Gallery'),
            ],
          ),
        );

        await tester.tap(find.byTooltip('Add attachment'));
        await tester.pumpAndSettle();

        expect(find.text('Poll'), findsOneWidget);
        expect(find.text('Document'), findsOneWidget);
        expect(find.text('Gallery'), findsOneWidget);
        expect(find.text('Location'), findsNothing);
        expect(find.text('Camera'), findsOneWidget);
        expect(
          tester.getCenter(find.text('Poll')).dx,
          lessThan(tester.getCenter(find.text('Document')).dx),
        );
        expect(
          tester.getCenter(find.text('Document')).dx,
          lessThan(tester.getCenter(find.text('Camera')).dx),
        );
        expect(
          tester.getCenter(find.text('Camera')).dx,
          lessThan(tester.getCenter(find.text('Gallery')).dx),
        );
      },
    );

    testWidgets('location appears only when a Maps key is configured', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _ComposerHost(
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [VAttachmentAction.location()],
          googleMapsApiKey: 'test-key',
        ),
      );

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();

      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('camera can be panel-only or both panel and quick launcher', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _ComposerHost(
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          showCameraLauncher: false,
          enableVoiceRecording: false,
        ),
      );
      expect(find.byTooltip('Open camera'), findsNothing);
      expect(
        tester
            .widget<MessageTextFiled>(find.byType(MessageTextFiled))
            .showCameraButton,
        isFalse,
      );

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();
      expect(find.text('Camera'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        const _ComposerHost(
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          showCameraLauncher: true,
          enableVoiceRecording: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MessageTextFiled>(find.byType(MessageTextFiled))
            .showCameraButton,
        isTrue,
      );
      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();
      expect(find.text('Camera'), findsOneWidget);
    });

    testWidgets('new media action routes through the existing picker', (
      tester,
    ) async {
      final originalPlatform = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _FakeFilePickerPlatform([
        _MemoryPlatformFile('photo.jpg', Uint8List(4)),
      ]);
      addTearDown(() => FilePickerPlatform.instance = originalPlatform);
      List<VPlatformFile>? submittedMedia;
      await tester.pumpWidget(
        _ComposerHost(
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: const [VAttachmentAction.media()],
          onSubmitMedia: (files) => submittedMedia = files,
        ),
      );

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();

      expect(submittedMedia, hasLength(1));
      expect(submittedMedia!.single.name, 'photo.jpg');
      expect(find.text('Media'), findsNothing);
    });

    testWidgets('picker cancellation preserves the draft and closed keyboard', (
      tester,
    ) async {
      final originalPlatform = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _FakeFilePickerPlatform(const []);
      addTearDown(() => FilePickerPlatform.instance = originalPlatform);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _ComposerHost(
          focusNode: focusNode,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: const [VAttachmentAction.files()],
        ),
      );
      await tester.enterText(find.byType(CupertinoTextField), 'draft');
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Files'));
      await tester.pumpAndSettle();

      expect(find.text('draft'), findsOneWidget);
      expect(focusNode.hasFocus, isFalse);
      expect(find.text('Files'), findsNothing);
    });

    testWidgets('custom panel builder replaces the inline panel body', (
      tester,
    ) async {
      var pollCount = 0;
      await tester.pumpWidget(
        _ComposerHost(
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [
            VAttachmentAction.custom(
              id: 'poll',
              label: 'Poll',
              icon: const Icon(Icons.poll),
              onPressed: (_) => pollCount++,
            ),
          ],
          attachmentPanelBuilder: (context, actions, controller) {
            return TextButton(
              onPressed: () => unawaited(controller.select(actions.single)),
              child: const Text('Build a poll'),
            );
          },
        ),
      );

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();
      expect(find.text('Build a poll'), findsOneWidget);
      expect(find.text('Poll'), findsNothing);

      await tester.tap(find.text('Build a poll'));
      await tester.pumpAndSettle();
      expect(pollCount, 1);
    });

    testWidgets('custom panel builder also replaces and closes a modal body', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ComposerHost(
          attachmentPresentation: VAttachmentPresentation.modalBottomSheet,
          attachmentActions: [_pollAction()],
          attachmentPanelBuilder: (context, actions, controller) {
            return TextButton(
              onPressed: controller.close,
              child: const Text('Close custom modal'),
            );
          },
        ),
      );

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();
      expect(find.text('Close custom modal'), findsOneWidget);
      expect(find.text('Poll'), findsNothing);

      await tester.tap(find.text('Close custom modal'));
      await tester.pumpAndSettle();
      expect(find.text('Close custom modal'), findsNothing);
    });

    testWidgets('duplicate action ids fail with a clear argument error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ComposerHost(
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [
            _pollAction(),
            _pollAction(label: 'Vote'),
          ],
        ),
      );

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pump();

      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('async action dispatch ignores rapid double taps', (
      tester,
    ) async {
      final completer = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        _ComposerHost(
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [
            VAttachmentAction.custom(
              id: 'poll',
              label: 'Poll',
              icon: const Icon(Icons.poll),
              onPressed: (_) {
                calls++;
                return completer.future;
              },
            ),
          ],
        ),
      );
      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Poll'));
      await tester.tap(find.text('Poll'));
      expect(calls, 1);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });

  group('composer surface coordination', () {
    testWidgets('zero keyboard inset opens the inline tray immediately', (
      tester,
    ) async {
      final controller = VMessageInputController();
      await tester.pumpWidget(
        _ComposerHost(
          controller: controller,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [_pollAction()],
        ),
      );

      controller.showAttachments();
      await tester.pump();

      expect(controller.activePanel, VComposerPanel.attachments);
      expect(find.text('Poll'), findsOneWidget);
    });

    testWidgets('positive keyboard inset defers the latest requested panel', (
      tester,
    ) async {
      final controller = VMessageInputController();
      final hostKey = GlobalKey<_MutableComposerHostState>();
      await tester.pumpWidget(
        _MutableComposerHost(
          key: hostKey,
          controller: controller,
          initialBottomInset: 280,
        ),
      );

      controller
        ..showAttachments()
        ..showEmoji()
        ..showAttachments();
      await tester.pump();
      expect(controller.activePanel, VComposerPanel.none);
      expect(find.text('Poll'), findsNothing);

      hostKey.currentState!.setBottomInset(0);
      await tester.pump();
      await tester.pump();

      expect(controller.activePanel, VComposerPanel.attachments);
      expect(find.text('Poll'), findsOneWidget);
    });

    testWidgets('emoji and attachments replace one another', (tester) async {
      final controller = VMessageInputController();
      await tester.pumpWidget(
        _ComposerHost(
          controller: controller,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [_pollAction()],
        ),
      );

      controller.showEmoji();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.activePanel, VComposerPanel.emoji);
      expect(find.text('Poll'), findsNothing);

      controller.showAttachments();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.activePanel, VComposerPanel.attachments);
      expect(find.text('Poll'), findsOneWidget);

      controller.showEmoji();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.activePanel, VComposerPanel.emoji);
      expect(find.text('Poll'), findsNothing);

      controller.closePanel();
      await tester.pumpAndSettle();
    });

    testWidgets('keyboard launcher closes the tray and restores focus', (
      tester,
    ) async {
      final controller = VMessageInputController();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _ComposerHost(
          controller: controller,
          focusNode: focusNode,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [_pollAction()],
        ),
      );

      controller.showAttachments();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Show keyboard'), findsOneWidget);

      await tester.tap(find.byTooltip('Show keyboard'));
      await tester.pumpAndSettle();

      expect(controller.activePanel, VComposerPanel.none);
      expect(focusNode.hasFocus, isTrue);
      expect(find.text('Poll'), findsNothing);
    });

    testWidgets('tapping the input closes the tray without losing the draft', (
      tester,
    ) async {
      final controller = VMessageInputController();
      final typingStates = <RoomTypingEnum>[];
      await tester.pumpWidget(
        _ComposerHost(
          controller: controller,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [_pollAction()],
          replyWidget: const Text('Replying to Sam'),
          onTypingChange: typingStates.add,
        ),
      );
      await tester.enterText(find.byType(CupertinoTextField), 'hello');
      final textField = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      textField.controller!.selection = const TextSelection.collapsed(
        offset: 2,
      );
      final activityCount = typingStates.length;

      controller.showAttachments();
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('Replying to Sam'), findsOneWidget);
      expect(find.byTooltip('Send message'), findsOneWidget);
      expect(textField.controller!.selection.baseOffset, 2);
      expect(typingStates, hasLength(activityCount));

      await tester.tap(find.byType(CupertinoTextField));
      await tester.pumpAndSettle();
      expect(controller.activePanel, VComposerPanel.none);
      expect(textField.controller!.text, 'hello');
      expect(textField.controller!.selection.isValid, isTrue);
      expect(typingStates, hasLength(activityCount));
    });

    testWidgets('mention results survive an attachment panel transition', (
      tester,
    ) async {
      final controller = VMessageInputController();
      await tester.pumpWidget(
        _ComposerHost(
          controller: controller,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [_pollAction()],
          onMentionSearch: (_) async => const [
            MentionModel(
              peerId: 'sam',
              name: 'Sam Wilson',
              image: 'https://example.com/sam.png',
            ),
          ],
        ),
      );

      await tester.enterText(find.byType(CupertinoTextField), '@sa');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.text('Sam Wilson'), findsOneWidget);

      controller.showAttachments();
      await tester.pumpAndSettle();

      expect(find.text('Sam Wilson'), findsOneWidget);
      expect(find.text('@sa'), findsOneWidget);
      expect(find.text('Poll'), findsOneWidget);
      controller.closePanel();
      await tester.pumpAndSettle();
    });

    testWidgets('system back closes a tray without popping the chat route', (
      tester,
    ) async {
      final controller = VMessageInputController();
      await tester.pumpWidget(
        _ComposerHost(
          controller: controller,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [_pollAction()],
          marker: const Text('Chat route'),
        ),
      );
      controller.showAttachments();
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(controller.activePanel, VComposerPanel.none);
      expect(find.text('Poll'), findsNothing);
      expect(find.text('Chat route'), findsOneWidget);
    });

    testWidgets('external focus closes an active custom panel', (tester) async {
      final controller = VMessageInputController();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _ComposerHost(
          controller: controller,
          focusNode: focusNode,
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentActions: [_pollAction()],
        ),
      );
      controller.showAttachments();
      await tester.pumpAndSettle();

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(controller.activePanel, VComposerPanel.none);
      expect(find.text('Poll'), findsNothing);
    });

    testWidgets('disabling attachments cancels a pending transition', (
      tester,
    ) async {
      final controller = VMessageInputController();
      final hostKey = GlobalKey<_MutableComposerHostState>();
      await tester.pumpWidget(
        _MutableComposerHost(
          key: hostKey,
          controller: controller,
          initialBottomInset: 240,
        ),
      );
      controller.showAttachments();
      await tester.pump();

      hostKey.currentState!
        ..setAttachmentsEnabled(false)
        ..setBottomInset(0);
      await tester.pump();
      await tester.pump();

      expect(controller.activePanel, VComposerPanel.none);
      expect(find.text('Poll'), findsNothing);
      expect(find.byTooltip('Add attachment'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      expect(controller.activePanel, VComposerPanel.none);
      expect(controller.showAttachments, returnsNormally);
      controller.dispose();
    });

    testWidgets('replacing a controller detaches the previous owner', (
      tester,
    ) async {
      final firstController = VMessageInputController();
      final secondController = VMessageInputController();
      final hostKey = GlobalKey<_MutableComposerHostState>();
      await tester.pumpWidget(
        _MutableComposerHost(key: hostKey, controller: firstController),
      );

      hostKey.currentState!.setController(secondController);
      await tester.pump();
      firstController.showAttachments();
      await tester.pump();
      expect(find.text('Poll'), findsNothing);

      secondController.showAttachments();
      await tester.pump();
      expect(find.text('Poll'), findsOneWidget);
      expect(firstController.activePanel, VComposerPanel.none);
      expect(secondController.activePanel, VComposerPanel.attachments);

      await tester.pumpWidget(const SizedBox());
      expect(() => firstController.addListener(() {}), returnsNormally);
      expect(() => secondController.addListener(() {}), returnsNormally);
      firstController.dispose();
      secondController.dispose();
    });
  });

  group('layout and accessibility', () {
    testWidgets(
      'outside launchers use logical leading and trailing positions',
      (tester) async {
        await tester.pumpWidget(
          const _ComposerHost(
            textDirection: TextDirection.rtl,
            launcherPlacement: VAttachmentLauncherPlacement.leadingOutside,
            enableCamera: false,
            enableVoiceRecording: false,
          ),
        );

        final launcher = find.byKey(const ValueKey('v_attachment_launcher'));
        expect(launcher, findsOneWidget);
        expect(
          tester.getCenter(launcher).dx,
          greaterThan(tester.getCenter(find.byType(CupertinoTextField)).dx),
        );

        await tester.pumpWidget(
          const _ComposerHost(
            textDirection: TextDirection.rtl,
            launcherPlacement: VAttachmentLauncherPlacement.trailingOutside,
            enableCamera: false,
            enableVoiceRecording: false,
          ),
        );
        await tester.pump();
        expect(
          tester.getCenter(launcher).dx,
          lessThan(tester.getCenter(find.byType(CupertinoTextField)).dx),
        );
      },
    );

    testWidgets('narrow large-text tray stays safe, scrollable, and semantic', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _ComposerHost(
          mediaSize: const Size(280, 600),
          textScaler: const TextScaler.linear(2),
          attachmentPresentation: VAttachmentPresentation.inlineTray,
          attachmentPanelLayout: VAttachmentPanelLayout.grid,
          attachmentActions: [
            for (var index = 0; index < 12; index++)
              VAttachmentAction.custom(
                id: 'custom-$index',
                label: 'Action $index',
                semanticLabel: 'Attachment action $index',
                icon: const Icon(Icons.extension_outlined),
                onPressed: (_) {},
              ),
          ],
        ),
      );

      await tester.tap(find.byTooltip('Add attachment'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Attachment actions'), findsOneWidget);
      expect(find.bySemanticsLabel('Attachment action 0'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets(
      'wrap and horizontal layouts render their intended containers',
      (tester) async {
        for (final layout in [
          VAttachmentPanelLayout.wrap,
          VAttachmentPanelLayout.horizontalList,
        ]) {
          await tester.pumpWidget(
            _ComposerHost(
              attachmentPresentation: VAttachmentPresentation.inlineTray,
              attachmentPanelLayout: layout,
              attachmentActions: [_pollAction()],
            ),
          );
          await tester.tap(find.byTooltip('Add attachment'));
          await tester.pumpAndSettle();

          if (layout == VAttachmentPanelLayout.wrap) {
            expect(find.byType(Wrap), findsOneWidget);
            expect(find.byType(SingleChildScrollView), findsOneWidget);
          } else {
            expect(find.byType(ListView), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  });
}

VAttachmentAction _pollAction({String label = 'Poll'}) {
  return VAttachmentAction.custom(
    id: 'poll',
    label: label,
    icon: const Icon(Icons.poll_outlined),
    onPressed: (_) {},
  );
}

VMessageInputWidget _composer() {
  return VMessageInputWidget(
    onSubmitText: (_) {},
    onSubmitMedia: (_) {},
    onSubmitFiles: (_) {},
    onSubmitLocation: (_) {},
    onSubmitVoice: (_) {},
    onTypingChange: (_) {},
  );
}

class _ComposerHost extends StatelessWidget {
  const _ComposerHost({
    this.controller,
    this.focusNode,
    this.attachmentPresentation = VAttachmentPresentation.adaptiveActionSheet,
    this.attachmentActions,
    this.attachmentPanelLayout,
    this.attachmentPanelBuilder,
    this.launcherPlacement = VAttachmentLauncherPlacement.insideInput,
    this.onAttachIconPress,
    this.onSubmitMedia,
    this.onTypingChange,
    this.onMentionSearch,
    this.googleMapsApiKey,
    this.replyWidget,
    this.marker,
    this.enableAttachments = true,
    this.enableCamera = true,
    this.enableVoiceRecording = true,
    this.showCameraLauncher = true,
    this.textDirection = TextDirection.ltr,
    this.mediaSize = const Size(800, 600),
    this.textScaler = TextScaler.noScaling,
    this.bottomInset = 0,
  });

  final VMessageInputController? controller;
  final FocusNode? focusNode;
  final VAttachmentPresentation attachmentPresentation;
  final List<VAttachmentAction>? attachmentActions;
  final VAttachmentPanelLayout? attachmentPanelLayout;
  final VAttachmentPanelBuilder? attachmentPanelBuilder;
  final VAttachmentLauncherPlacement launcherPlacement;
  final Future<AttachEnumRes?> Function()? onAttachIconPress;
  final ValueChanged<List<VPlatformFile>>? onSubmitMedia;
  final ValueChanged<RoomTypingEnum>? onTypingChange;
  final Future<List<MentionModel>> Function(String)? onMentionSearch;
  final String? googleMapsApiKey;
  final Widget? replyWidget;
  final Widget? marker;
  final bool enableAttachments;
  final bool enableCamera;
  final bool enableVoiceRecording;
  final bool showCameraLauncher;
  final TextDirection textDirection;
  final Size mediaSize;
  final TextScaler textScaler;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: MediaQuery(
          data: MediaQueryData(
            size: mediaSize,
            viewInsets: EdgeInsets.only(bottom: bottomInset),
            textScaler: textScaler,
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                ?marker,
                const Spacer(),
                VMessageInputWidget(
                  controller: controller,
                  focusNode: focusNode,
                  attachmentPresentation: attachmentPresentation,
                  attachmentActions: attachmentActions,
                  attachmentPanelLayout: attachmentPanelLayout,
                  attachmentPanelBuilder: attachmentPanelBuilder,
                  attachmentLauncherPlacement: launcherPlacement,
                  onAttachIconPress: onAttachIconPress,
                  replyWidget: replyWidget,
                  enableAttachments: enableAttachments,
                  enableCamera: enableCamera,
                  enableVoiceRecording: enableVoiceRecording,
                  showCameraLauncher: showCameraLauncher,
                  onSubmitText: (_) {},
                  onSubmitMedia: onSubmitMedia ?? (_) {},
                  onSubmitFiles: (_) {},
                  onSubmitLocation: (_) {},
                  onSubmitVoice: (_) {},
                  onTypingChange: onTypingChange ?? (_) {},
                  onMentionSearch: onMentionSearch,
                  googleMapsApiKey: googleMapsApiKey,
                  mentionItemBuilder: onMentionSearch == null
                      ? null
                      : (mention) => Text(mention.name),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MutableComposerHost extends StatefulWidget {
  const _MutableComposerHost({
    super.key,
    required this.controller,
    this.initialBottomInset = 0,
  });

  final VMessageInputController controller;
  final double initialBottomInset;

  @override
  State<_MutableComposerHost> createState() => _MutableComposerHostState();
}

class _MutableComposerHostState extends State<_MutableComposerHost> {
  late double _bottomInset;
  late VMessageInputController _controller;
  bool _enableAttachments = true;

  @override
  void initState() {
    super.initState();
    _bottomInset = widget.initialBottomInset;
    _controller = widget.controller;
  }

  void setBottomInset(double value) {
    setState(() => _bottomInset = value);
  }

  void setAttachmentsEnabled(bool value) {
    setState(() => _enableAttachments = value);
  }

  void setController(VMessageInputController value) {
    setState(() => _controller = value);
  }

  @override
  Widget build(BuildContext context) {
    return _ComposerHost(
      controller: _controller,
      bottomInset: _bottomInset,
      enableAttachments: _enableAttachments,
      attachmentPresentation: VAttachmentPresentation.inlineTray,
      attachmentActions: [_pollAction()],
    );
  }
}

class _FakeFilePickerPlatform extends FilePickerPlatform {
  _FakeFilePickerPlatform(this.files);

  final List<PlatformFile> files;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return files;
  }
}

base class _MemoryPlatformFile extends PlatformFile {
  _MemoryPlatformFile(this.name, this.data);

  @override
  final String name;
  final Uint8List data;

  @override
  Uri get uri => Uri.parse('memory:$name');

  @override
  XFile get xFile => XFile.fromData(data, name: name);

  @override
  Future<int> length() async => data.length;

  @override
  Future<Uint8List> readAsBytes() async => data;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(data);
}

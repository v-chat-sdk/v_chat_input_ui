import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_chat_input_ui/v_chat_input_ui.dart';
import 'package:v_platform/v_platform.dart';

import 'support/deferred_record_channel.dart';

Widget _app({
  required TextEditingController draft,
  required ValueChanged<MessageVoiceData> onVoice,
  required ValueChanged<RoomTypingEnum> onActivity,
  required bool stopped,
}) => MaterialApp(
  home: Scaffold(
    body: VMessageInputWidget(
      textController: draft,
      stopChatWidget: stopped ? const Text('Unavailable') : null,
      enableEmojiPicker: false,
      enableAttachments: false,
      enableCamera: false,
      recordingWidgetBuilder: (context, state, cancel) =>
          TextButton(onPressed: cancel, child: const Text('Cancel capture')),
      onSubmitText: (_) {},
      onSubmitFiles: (_) {},
      onSubmitMedia: (_) {},
      onSubmitLocation: (_) {},
      onSubmitVoice: onVoice,
      onTypingChange: onActivity,
    ),
  ),
);

Future<void> _start(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Record voice message'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Send message'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 11));
}

Future<void> _waitForDisposal(
  WidgetTester tester,
  DeferredRecordChannel native,
  String id,
) async {
  for (var frame = 0; frame < 10 && !native.disposed.contains(id); frame++) {
    // Method-channel replies complete outside the widget clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  expect(native.disposed, contains(id));
}

void main() {
  testWidgets('Cancel ignores a late completion from a pending voice send', (
    tester,
  ) async {
    final wasWeb = VPlatforms.isWeb;
    VPlatforms.isWeb = true;
    final native = DeferredRecordChannel(
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
    )..install();
    addTearDown(() {
      native.uninstall();
      VPlatforms.isWeb = wasWeb;
    });
    final draft = TextEditingController();
    final voices = <MessageVoiceData>[];
    await tester.pumpWidget(
      _app(
        draft: draft,
        onVoice: voices.add,
        onActivity: (_) {},
        stopped: false,
      ),
    );
    await _start(tester);
    final id = native.created.single;
    final stop = native.deferStop(id);
    await _send(tester);
    expect(native.stopCalls, [id]);
    await tester.tap(find.text('Cancel capture'));
    await tester.pump();
    expect(find.byType(CupertinoTextField), findsOneWidget);
    stop.complete(null);
    await tester.pump();
    await tester.pump();
    expect(voices, isEmpty);
    expect(tester.takeException(), isNull);
    await _waitForDisposal(tester, native, id);
    await tester.pumpWidget(const SizedBox());
    draft.dispose();
  });

  testWidgets(
    'blocked and resumed recording ignores the previous session finish',
    (tester) async {
      final wasWeb = VPlatforms.isWeb;
      VPlatforms.isWeb = true;
      final native = DeferredRecordChannel(
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
      )..install();
      addTearDown(() {
        native.uninstall();
        VPlatforms.isWeb = wasWeb;
      });
      final draft = TextEditingController();
      final voices = <MessageVoiceData>[];
      final activity = <RoomTypingEnum>[];
      var blocked = false;
      late StateSetter update;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return _app(
              draft: draft,
              onVoice: voices.add,
              onActivity: activity.add,
              stopped: blocked,
            );
          },
        ),
      );
      await _start(tester);
      final oldId = native.created.single;
      final stop = native.deferStop(oldId);
      draft.value = const TextEditingValue(
        text: 'Unsent text',
        selection: TextSelection.collapsed(offset: 4),
      );
      final retained = draft.value;
      await _send(tester);
      expect(native.stopCalls, [oldId]);
      update(() => blocked = true);
      await tester.pump();
      expect(draft.value, retained);
      expect(activity.last, RoomTypingEnum.stop);
      update(() => blocked = false);
      await tester.pump();
      draft.clear();
      await tester.pump();
      await _start(tester);
      final freshId = native.created.last;
      expect(freshId, isNot(oldId));
      expect(native.active, contains(freshId));
      stop.complete(null);
      await tester.pump();
      await tester.pump();
      await _waitForDisposal(tester, native, oldId);
      expect(voices, isEmpty);
      expect(tester.takeException(), isNull);
      expect(find.text('Cancel capture'), findsOneWidget);
      expect(native.active, contains(freshId));
      expect(native.disposed, isNot(contains(freshId)));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pump();
      draft.dispose();
    },
  );
}

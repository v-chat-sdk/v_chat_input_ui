// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_chat_input_ui/src/input/widgets/message_record_btn.dart';
import 'package:v_chat_input_ui/src/input/widgets/message_send_btn.dart';
import 'package:v_chat_input_ui/src/recorder/record_widget.dart';
import 'package:v_chat_input_ui/src/recorder/recorders.dart';
import 'package:v_chat_input_ui/v_chat_input_ui.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  test('VRecordingState exposes safe progress values', () {
    const active = VRecordingState(
      elapsed: Duration(seconds: 15),
      maxDuration: Duration(seconds: 30),
      elapsedLabel: '00:15',
      cancelLabel: 'Cancel recording',
    );
    const exceeded = VRecordingState(
      elapsed: Duration(seconds: 45),
      maxDuration: Duration(seconds: 30),
      elapsedLabel: '00:45',
      cancelLabel: 'Cancel recording',
    );
    const noLimit = VRecordingState(
      elapsed: Duration.zero,
      maxDuration: Duration.zero,
      elapsedLabel: '00:00',
      cancelLabel: 'Cancel recording',
    );

    expect(active.progress, 0.5);
    expect(exceeded.progress, 1);
    expect(noLimit.progress, 0);
  });

  testWidgets('Send and Record controls honor the shared themed extent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [VInputTheme.light(composerActionExtent: 56)],
        ),
        home: Scaffold(
          body: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MessageSendBtn(semanticLabel: 'Send', onSend: () {}),
              MessageRecordBtn(semanticLabel: 'Record', onRecordClick: () {}),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(MessageSendBtn)), const Size.square(56));
    expect(
      tester.getSize(find.byType(MessageRecordBtn)),
      const Size.square(56),
    );
    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(MessageSendBtn),
          matching: find.byType(Container),
        ),
      ),
      const Size.square(56),
    );
    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(MessageRecordBtn),
          matching: find.byType(Container),
        ),
      ),
      const Size.square(56),
    );
  });

  testWidgets('one-line input and Send control use the same height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [VInputTheme.light(composerActionExtent: 52)],
        ),
        home: Scaffold(
          body: _composer(
            enableEmojiPicker: false,
            enableAttachments: false,
            enableCamera: false,
            enableVoiceRecording: false,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(CupertinoTextField), 'Ready to send');
    await tester.pump();

    final inputSize = tester.getSize(
      find.byKey(const ValueKey('v_message_input_container')),
    );
    final sendSize = tester.getSize(find.byType(MessageSendBtn));

    expect(inputSize.height, 52);
    expect(sendSize, const Size.square(52));
  });

  testWidgets(
    'custom recording builder receives live state and cancel action',
    (tester) async {
      final originalIsWeb = VPlatforms.isWeb;
      VPlatforms.isWeb = true;
      addTearDown(() => VPlatforms.isWeb = originalIsWeb);
      var cancelCount = 0;
      VRecordingState? latestState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordWidget(
              maxTime: const Duration(seconds: 30),
              onMaxTime: () {},
              cancelRecordingLabel: 'Discard voice message',
              onCancel: () => cancelCount++,
              recorderFactory: _FakeRecorder.new,
              builder: (context, state, onCancel) {
                latestState = state;
                return TextButton(
                  onPressed: onCancel,
                  child: Text('Custom ${state.elapsedLabel}'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Custom 00:00'), findsOneWidget);
      expect(latestState?.maxDuration, const Duration(seconds: 30));
      expect(latestState?.cancelLabel, 'Discard voice message');

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(seconds: 1));
      expect(latestState!.elapsed, greaterThan(Duration.zero));

      await tester.tap(find.byType(TextButton));
      expect(cancelCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('built-in recording widget remains the default', (tester) async {
    final originalIsWeb = VPlatforms.isWeb;
    VPlatforms.isWeb = true;
    addTearDown(() => VPlatforms.isWeb = originalIsWeb);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordWidget(
            maxTime: const Duration(seconds: 30),
            onMaxTime: () {},
            cancelRecordingLabel: 'Discard voice message',
            onCancel: () {},
            recorderFactory: _FakeRecorder.new,
          ),
        ),
      ),
    );

    expect(find.text('00:00'), findsOneWidget);
    expect(find.byTooltip('Discard voice message'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

VMessageInputWidget _composer({
  required bool enableEmojiPicker,
  required bool enableAttachments,
  required bool enableCamera,
  required bool enableVoiceRecording,
}) {
  return VMessageInputWidget(
    enableEmojiPicker: enableEmojiPicker,
    enableAttachments: enableAttachments,
    enableCamera: enableCamera,
    enableVoiceRecording: enableVoiceRecording,
    onSubmitText: (_) {},
    onSubmitMedia: (_) {},
    onSubmitFiles: (_) {},
    onSubmitLocation: (_) {},
    onSubmitVoice: (_) {},
    onTypingChange: (_) {},
  );
}

class _FakeRecorder extends AppRecorder {
  @override
  Future<void> close() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> isRecording() async => true;

  @override
  Future<void> pause() async {}

  @override
  Future<void> start([String? path]) async {}

  @override
  Future<String?> stop() async => 'fake-recording.aac';
}

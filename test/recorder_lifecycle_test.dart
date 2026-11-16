import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_chat_input_ui/src/recorder/record_widget.dart';
import 'package:v_platform/v_platform.dart';

import 'support/deferred_start_recorder.dart';

void main() {
  testWidgets(
    'removal during native start stops recording after start settles',
    (tester) async {
      final wasWeb = VPlatforms.isWeb;
      VPlatforms.isWeb = true;
      addTearDown(() => VPlatforms.isWeb = wasWeb);
      final recorder = DeferredStartRecorder();
      var cancelled = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: RecordWidget(
            maxTime: const Duration(minutes: 1),
            onMaxTime: () {},
            cancelRecordingLabel: 'Cancel',
            onCancel: () => cancelled++,
            recorderFactory: () => recorder,
          ),
        ),
      );
      expect(recorder.events, ['start']);
      await tester.pumpWidget(const SizedBox());
      expect(recorder.events, ['start']);
      recorder.startGate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(recorder.events, ['start', 'started', 'stop', 'close']);
      expect(recorder.active, isFalse);
      expect(cancelled, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Send waits for native startup and shares stop with removal', (
    tester,
  ) async {
    final wasWeb = VPlatforms.isWeb;
    VPlatforms.isWeb = true;
    addTearDown(() => VPlatforms.isWeb = wasWeb);
    final recorder = DeferredStartRecorder();
    final key = GlobalKey<RecordWidgetState>();
    await tester.pumpWidget(
      MaterialApp(
        home: RecordWidget(
          key: key,
          maxTime: const Duration(minutes: 1),
          onMaxTime: () {},
          cancelRecordingLabel: 'Cancel',
          onCancel: () {},
          recorderFactory: () => recorder,
        ),
      ),
    );
    // This fake deliberately returns no file; ordering is the contract here.
    final stopped = expectLater(
      key.currentState!.stopRecord(),
      throwsStateError,
    );
    expect(recorder.events, ['start']);
    recorder.startGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 11));
    await stopped;
    expect(recorder.events, ['start', 'started', 'isRecording', 'stop']);
    expect(recorder.active, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(recorder.events, [
      'start',
      'started',
      'isRecording',
      'stop',
      'close',
    ]);
    expect(tester.takeException(), isNull);
  });
}

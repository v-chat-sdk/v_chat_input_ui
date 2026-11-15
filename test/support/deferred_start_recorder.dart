import 'dart:async';

import 'package:v_chat_input_ui/src/recorder/recorders.dart';

class DeferredStartRecorder extends AppRecorder {
  final startGate = Completer<void>();
  final events = <String>[];
  bool active = false;

  @override
  Future<void> start([String? path]) async {
    events.add('start');
    await startGate.future;
    active = true;
    events.add('started');
  }

  @override
  Future<String?> stop() async {
    events.add('stop');
    active = false;
    return null;
  }

  @override
  Future<void> close() async {
    events.add('close');
  }

  @override
  Future<bool> isRecording() async {
    events.add('isRecording');
    return active;
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> pause() async {}
}

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the real AudioRecorder wrapper through its native channel contract.
class DeferredRecordChannel {
  DeferredRecordChannel(this.messenger);

  final TestDefaultBinaryMessenger messenger;
  static const channel = MethodChannel('com.llfbandit.record/messages');
  final created = <String>[];
  final active = <String>{};
  final disposed = <String>[];
  final stopCalls = <String>[];
  final _pendingStops = <String, Completer<String?>>{};

  void install() => messenger.setMockMethodCallHandler(channel, _handle);

  Completer<String?> deferStop(String id) =>
      _pendingStops[id] = Completer<String?>();

  Future<Object?> _handle(MethodCall call) async {
    final arguments = call.arguments as Map<Object?, Object?>;
    final id = arguments['recorderId']! as String;
    switch (call.method) {
      case 'create':
        created.add(id);
        messenger.setMockMethodCallHandler(
          MethodChannel('com.llfbandit.record/events/$id'),
          (_) async => null,
        );
        return null;
      case 'start':
        active.add(id);
        return null;
      case 'isRecording':
        return active.contains(id);
      case 'hasPermission':
        return true;
      case 'stop':
        stopCalls.add(id);
        final gate = _pendingStops[id];
        final result = gate == null ? null : await gate.future;
        active.remove(id);
        return result;
      case 'dispose':
        disposed.add(id);
        return null;
      case 'pause':
        return null;
      default:
        throw StateError('Unexpected recorder call ${call.method}');
    }
  }

  void uninstall() {
    messenger.setMockMethodCallHandler(channel, null);
    for (final id in created) {
      messenger.setMockMethodCallHandler(
        MethodChannel('com.llfbandit.record/events/$id'),
        null,
      );
    }
  }
}

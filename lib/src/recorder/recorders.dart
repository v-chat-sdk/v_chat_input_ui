// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:v_platform/v_platform.dart';

abstract class AppRecorder {
  Future<void> start([String? path]);

  Future<String?> stop();

  Future<void> pause();

  Future<bool> isRecording();

  Future<bool> hasPermission();

  Future<void> close();
}
// ///i have stop this MobileRecorder since it make voice nose
// class MobileRecorder extends AppRecorder {
//   final recorder = RecorderController();
//
//   @override
//   Future<void> start([String? path]) async {
//     await recorder.record(path: path);
//   }
//
//   @override
//   Future<String?> stop() async {
//     final path = await recorder.stop();
//     if (path != null) {
//       return Uri.parse(path).path;
//     }
//     return null;
//   }
//
//   @override
//   Future pause() async {
//     await recorder.pause();
//   }
//
//   @override
//   Future close() async {
//     recorder.dispose();
//   }
//
//   @override
//   Future<bool> isRecording() async {
//     return recorder.isRecording;
//   }
// }

class PlatformRecorder extends AppRecorder {
  final recorder = AudioRecorder();

  @override
  Future<void> close() async {
    await recorder.dispose();
  }

  @override
  Future<void> pause() async {
    await recorder.pause();
  }

  @override
  Future<void> start([String? path]) async {
    var encoder = const RecordConfig(
      encoder: AudioEncoder.aacLc,
      numChannels: 1,
    );
    if (kIsWeb) {
      encoder = const RecordConfig(encoder: AudioEncoder.opus);
    }
    if (VPlatforms.isMobile && path == null) {
      throw ArgumentError("A file path is required when recording on mobile.");
    }

    await recorder.start(encoder, path: path ?? "");
  }

  @override
  Future<bool> isRecording() async {
    return recorder.isRecording();
  }

  @override
  Future<String?> stop() async {
    return recorder.stop();
  }

  @override
  Future<bool> hasPermission() {
    return recorder.hasPermission();
  }
}

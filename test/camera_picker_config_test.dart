// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_chat_input_ui/src/v_widgets/app_pick.dart';

void main() {
  group('VAppPick.buildCameraPickerConfig', () {
    test('locks capture orientation to portrait', () {
      final config = VAppPick.buildCameraPickerConfig();
      expect(config.lockCaptureOrientation, DeviceOrientation.portraitUp);
    });

    test('forwards recording and duration options', () {
      final config = VAppPick.buildCameraPickerConfig(videoSeconds: 30);
      expect(config.enableRecording, isTrue);
      expect(config.enableTapRecording, isTrue);
      expect(config.maximumRecordingDuration, const Duration(seconds: 30));
      expect(config.shouldAutoPreviewVideo, isTrue);
    });
  });
}

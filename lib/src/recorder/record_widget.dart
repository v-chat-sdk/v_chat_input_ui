// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import 'package:path_provider/path_provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import 'package:uuid/uuid.dart';
import 'package:v_chat_input_ui/src/recorder/recorders.dart';
import 'package:v_chat_input_ui/src/v_widgets/extension.dart';
import 'package:v_platform/v_platform.dart';

import '../models/models.dart';

class RecordWidget extends StatefulWidget {
  final Duration maxTime;
  final VoidCallback onMaxTime;
  final String cancelRecordingLabel;
  final VRecordingWidgetBuilder? builder;

  @visibleForTesting
  final AppRecorder Function()? recorderFactory;

  const RecordWidget({
    super.key,
    required this.onCancel,
    required this.maxTime,
    required this.onMaxTime,
    required this.cancelRecordingLabel,
    this.builder,
    this.recorderFactory,
  });

  final VoidCallback onCancel;

  @override
  State<RecordWidget> createState() => RecordWidgetState();
}

class RecordWidgetState extends State<RecordWidget> {
  final _stopWatchTimer = StopWatchTimer();
  String _currentTime = "00:00";
  int _recordMilli = 0;
  final _uuid = const Uuid();
  AppRecorder? _recorder;
  StreamSubscription? _rawTime;
  bool _hasReachedMaxTime = false;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _recorder = widget.recorderFactory?.call() ?? PlatformRecorder();
    _rawTime = _stopWatchTimer.rawTime.listen((value) {
      _recordMilli = value;
      _currentTime = StopWatchTimer.getDisplayTime(
        value,
        hours: false,
        milliSecond: false,
      );
      if (mounted) {
        setState(() {});
      }
      if (!_hasReachedMaxTime && value >= widget.maxTime.inMilliseconds) {
        _hasReachedMaxTime = true;
        unawaited(_completeAtMaxTime());
      }
    });
    _start();
  }

  void startCounterUp() {
    if (_stopWatchTimer.isRunning) {
      _stopCounter();
    }
    _stopWatchTimer.onStartTimer();
  }

  Future<void> _stopCounter() async {
    _stopWatchTimer.onResetTimer();
    _stopWatchTimer.onStopTimer();
    _recordMilli = 0;
  }

  Future<void> pause() async {
    _stopWatchTimer.onStopTimer();
    await _recorder?.pause();
  }

  Future<void> _completeAtMaxTime() async {
    await pause();
    if (mounted) {
      widget.onMaxTime();
    }
  }

  Future<String> _getDir() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    return join(appDirectory.path, '${_uuid.v4()}.aac');
  }

  Future<bool> _start() async {
    if (VPlatforms.isWindows || VPlatforms.isLinux || VPlatforms.isMacOs) {
      return false;
    }
    if (VPlatforms.isWeb) {
      await _recorder!.start();
    } else {
      final path = await _getDir();
      await _recorder!.start(path);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    final isRecording = await _recorder!.isRecording();
    if (isRecording) {
      startCounterUp();
      return true;
    }
    return false;
  }

  Future<MessageVoiceData> stopRecord() async {
    _stopWatchTimer.onStopTimer();
    await Future.delayed(const Duration(milliseconds: 10));
    final path = await _recorder!.stop();
    if (path != null) {
      List<int>? bytes;
      if (VPlatforms.isWeb) {
        final xFile = XFile(path);
        bytes = await xFile.readAsBytes();
      }
      final uri = Uri.parse(path);
      final data = MessageVoiceData(
        duration: _recordMilli,
        fileSource: VPlatforms.isWeb
            ? VPlatformFile.fromBytes(
                name: "${DateTime.now().microsecondsSinceEpoch}.webm",
                bytes: bytes!,
              )
            : VPlatformFile.fromPath(fileLocalPath: uri.path),
      );
      return data;
    }
    throw StateError("The recorder stopped without returning an audio file.");
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = VRecordingState(
      elapsed: Duration(milliseconds: _recordMilli),
      maxDuration: widget.maxTime,
      elapsedLabel: _currentTime,
      cancelLabel: widget.cancelRecordingLabel,
    );
    final builder = widget.builder;
    if (builder != null) {
      return builder(context, recordingState, widget.onCancel);
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTime,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: context.isDark ? Colors.white : Colors.black54,
                ),
              ),

              const SizedBox(width: 15),
              // if (_recorder is MobileRecorder)
              //   Expanded(
              //     child: AudioWaveforms(
              //       size: Size(MediaQuery.of(context).size.width, 40.0),
              //       recorderController: (_recorder as MobileRecorder).recorder,
              //     ),
              //   )
              // else
              const SizedBox(height: 10),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                button: true,
                label: widget.cancelRecordingLabel,
                child: Tooltip(
                  message: widget.cancelRecordingLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onCancel,
                    child: ExcludeSemantics(
                      child: context.vInputTheme.trashIcon,
                    ),
                  ),
                ),
              ),
              // constGestureDetector(
              //   child: Icon(
              //     Icons.pause_circle_outline,
              //     size: 30,
              //     color: Colors.grey,
              //   ),
              // ),
              const SizedBox(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    _stopCounter();
    await _recorder?.stop();
    _stopWatchTimer.dispose();
    _rawTime?.cancel();
    await _recorder?.close();
  }
}

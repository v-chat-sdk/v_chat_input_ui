// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:material_ui/material_ui.dart';
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
  late final Future<bool> _startOperation;
  Future<void>? _closeOperation;
  Future<String?>? _stopOperation;

  @override
  void initState() {
    super.initState();
    _recorder = widget.recorderFactory?.call() ?? PlatformRecorder();
    _rawTime = _stopWatchTimer.rawTime.listen((value) {
      if (_isClosed) return;
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
    _startOperation = _start();
    unawaited(
      _startOperation.then<void>(
        (started) {
          if (!started && mounted && !_isClosed) widget.onCancel();
        },
        onError: (Object error, StackTrace stack) {
          if (_isClosed) return;
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'v_chat_input_ui',
              context: ErrorDescription('while starting voice recording'),
            ),
          );
          if (mounted) widget.onCancel();
        },
      ),
    );
  }

  void startCounterUp() {
    if (_isClosed) return;
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
    if (_isClosed) return;
    _stopWatchTimer.onStopTimer();
    await _recorder?.pause();
  }

  Future<void> _completeAtMaxTime() async {
    await pause();
    if (mounted && !_isClosed) {
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
    final recorder = _recorder!;
    if (VPlatforms.isWeb) {
      await recorder.start();
    } else {
      final path = await _getDir();
      if (_isClosed) return false;
      await recorder.start(path);
    }
    if (_isClosed) return false;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (_isClosed) return false;
    final isRecording = await recorder.isRecording();
    if (_isClosed) return false;
    if (isRecording) {
      startCounterUp();
      return true;
    }
    return false;
  }

  Future<MessageVoiceData> stopRecord() async {
    if (_isClosed) throw StateError('The recorder is already closed.');
    final started = await _startOperation;
    if (_isClosed || !started) {
      throw StateError('The recorder is not active.');
    }
    _stopWatchTimer.onStopTimer();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (_isClosed) {
      throw StateError('The recorder was closed before submission.');
    }
    final path = await _stopRecording();
    if (_isClosed) {
      throw StateError('The recorder was closed during submission.');
    }
    if (path != null) {
      List<int>? bytes;
      if (VPlatforms.isWeb) {
        final xFile = XFile(path);
        bytes = await xFile.readAsBytes();
      }
      if (_isClosed) {
        throw StateError('The recorder was closed while reading audio.');
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
    unawaited(close());
    super.dispose();
  }

  Future<void> close() => _closeOperation ??= _close();

  Future<String?> _stopRecording() => _stopOperation ??= _recorder!.stop();

  Future<void> _close() async {
    _isClosed = true;
    await _stopCounter();
    // A native start may finish after removal. Await it before issuing the
    // shared stop operation, so neither removal nor Send can lose that race.
    try {
      try {
        await _startOperation;
      } catch (_) {
        // Startup errors are reported by the initialization handler above.
      }
      await _stopRecording();
    } finally {
      try {
        await _recorder?.close();
      } finally {
        await _rawTime?.cancel();
        await _stopWatchTimer.dispose();
      }
    }
  }
}

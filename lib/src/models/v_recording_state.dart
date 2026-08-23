// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Live, read-only data exposed while the composer records a voice message.
@immutable
class VRecordingState {
  const VRecordingState({
    required this.elapsed,
    required this.maxDuration,
    required this.elapsedLabel,
    required this.cancelLabel,
  });

  /// Time recorded so far.
  final Duration elapsed;

  /// Maximum duration configured on the message input widget.
  final Duration maxDuration;

  /// Preformatted elapsed time using the package recorder format.
  final String elapsedLabel;

  /// Localized label to use for a custom cancel control.
  final String cancelLabel;

  /// Recording progress clamped to the inclusive range from 0 to 1.
  double get progress {
    if (maxDuration.inMilliseconds <= 0) return 0;
    return (elapsed.inMilliseconds / maxDuration.inMilliseconds).clamp(0, 1);
  }
}

/// Builds the visual content shown inside the input while recording.
///
/// The package continues to own the recorder, timer, maximum-duration
/// handling, and cleanup. Call [onCancel] from the custom UI to safely cancel
/// the current recording. Submission remains available through the composer's
/// Send button.
typedef VRecordingWidgetBuilder =
    Widget Function(
      BuildContext context,
      VRecordingState state,
      VoidCallback onCancel,
    );

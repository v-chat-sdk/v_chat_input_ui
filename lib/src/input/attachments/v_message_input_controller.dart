// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'v_attachment_presentation.dart';

/// Controls the optional panels owned by [VMessageInputWidget].
class VMessageInputController extends ChangeNotifier {
  VComposerPanel _activePanel = VComposerPanel.none;
  Object? _owner;
  VoidCallback? _showAttachments;
  VoidCallback? _showEmoji;
  VoidCallback? _showKeyboard;
  VoidCallback? _closePanel;

  VComposerPanel get activePanel => _activePanel;

  void showAttachments() => _showAttachments?.call();

  void showEmoji() => _showEmoji?.call();

  void showKeyboard() => _showKeyboard?.call();

  void closePanel() => _closePanel?.call();

  @internal
  void attach({
    required Object owner,
    required VoidCallback showAttachments,
    required VoidCallback showEmoji,
    required VoidCallback showKeyboard,
    required VoidCallback closePanel,
  }) {
    if (_owner != null && !identical(_owner, owner)) {
      throw StateError(
        'A VMessageInputController cannot control multiple composers.',
      );
    }
    _owner = owner;
    _showAttachments = showAttachments;
    _showEmoji = showEmoji;
    _showKeyboard = showKeyboard;
    _closePanel = closePanel;
  }

  @internal
  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _showAttachments = null;
    _showEmoji = null;
    _showKeyboard = null;
    _closePanel = null;
  }

  @internal
  void updateActivePanel(Object owner, VComposerPanel panel) {
    if (!identical(_owner, owner) || panel == _activePanel) return;
    _activePanel = panel;
    notifyListeners();
  }
}

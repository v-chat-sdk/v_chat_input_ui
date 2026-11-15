import 'package:flutter/foundation.dart';

import 'v_attachment_action.dart';
import 'v_attachment_presentation.dart';

class AttachmentPanelController implements VAttachmentPresentationController {
  const AttachmentPanelController({
    required this.isPanelOpen,
    required this.selectAction,
    required this.closePanel,
    required this.showComposerKeyboard,
  });

  final bool Function() isPanelOpen;
  final Future<void> Function(VAttachmentAction action) selectAction;
  final VoidCallback closePanel;
  final VoidCallback showComposerKeyboard;

  @override
  bool get isOpen => isPanelOpen();

  @override
  Future<void> select(VAttachmentAction action) => selectAction(action);

  @override
  void close() => closePanel();

  @override
  void showKeyboard() => showComposerKeyboard();
}

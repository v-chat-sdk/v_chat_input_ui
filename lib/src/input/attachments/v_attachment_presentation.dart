// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'v_attachment_action.dart';

enum VAttachmentPresentation {
  adaptiveActionSheet,
  modalBottomSheet,
  inlineTray,
}

enum VAttachmentLauncherPlacement {
  insideInput,
  leadingOutside,
  trailingOutside,
}

enum VAttachmentPanelLayout { grid, horizontalList, wrap }

enum VComposerPanel { none, emoji, attachments }

abstract interface class VAttachmentPresentationController {
  bool get isOpen;

  Future<void> select(VAttachmentAction action);

  void close();

  void showKeyboard();
}

typedef VAttachmentPanelBuilder =
    Widget Function(
      BuildContext context,
      List<VAttachmentAction> actions,
      VAttachmentPresentationController controller,
    );

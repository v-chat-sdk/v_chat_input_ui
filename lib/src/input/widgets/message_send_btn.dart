// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:v_chat_input_ui/src/models/v_input_theme.dart';

class MessageSendBtn extends StatelessWidget {
  final VoidCallback onSend;
  final String semanticLabel;

  const MessageSendBtn({
    super.key,
    required this.onSend,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.vInputTheme;
    return SizedBox.square(
      dimension: theme.composerActionExtent,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Tooltip(
          message: semanticLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSend,
            child: ExcludeSemantics(child: theme.sendBtn),
          ),
        ),
      ),
    );
  }
}

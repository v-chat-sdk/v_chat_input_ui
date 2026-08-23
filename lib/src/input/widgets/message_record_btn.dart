// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:v_chat_input_ui/src/models/models.dart';

class MessageRecordBtn extends StatelessWidget {
  final VoidCallback onRecordClick;
  final String semanticLabel;

  const MessageRecordBtn({
    super.key,
    required this.onRecordClick,
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
            onTap: onRecordClick,
            child: ExcludeSemantics(child: theme.recordBtn),
          ),
        ),
      ),
    );
  }
}

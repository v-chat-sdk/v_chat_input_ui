// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:v_platform/v_platform.dart';

class EmojiKeyboard extends StatelessWidget {
  final bool isEmojiShowing;
  final TextEditingController controller;

  const EmojiKeyboard({
    super.key,
    required this.isEmojiShowing,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEmojiShowing) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: VPlatforms.isWeb ? MediaQuery.of(context).size.height / 3 : 250,
      child: EmojiPicker(textEditingController: controller),
    );
  }
}

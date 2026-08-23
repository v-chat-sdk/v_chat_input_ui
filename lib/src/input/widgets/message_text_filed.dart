// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:v_chat_input_ui/src/models/v_input_theme.dart';
import 'package:v_chat_mention_controller/v_chat_mention_controller.dart';
import 'package:v_platform/v_platform.dart';

import '../../v_widgets/auto_direction.dart';

class MessageTextFiled extends StatefulWidget {
  final VChatTextMentionController textEditingController;
  final FocusNode focusNode;
  final bool isTyping;
  final bool autofocus;
  final String hint;
  final VoidCallback onShowEmoji;
  final VoidCallback onCameraPress;
  final VoidCallback onAttachFilePress;
  final VoidCallback onInputTap;
  final Function(String value) onSubmit;
  final bool showEmojiButton;
  final bool showCameraButton;
  final bool showAttachmentButton;
  final String emojiButtonLabel;
  final String cameraButtonLabel;
  final String attachmentButtonLabel;
  final Widget attachmentIcon;

  const MessageTextFiled({
    super.key,
    required this.textEditingController,
    required this.focusNode,
    required this.onShowEmoji,
    required this.onCameraPress,
    required this.onAttachFilePress,
    required this.onInputTap,
    required this.isTyping,
    required this.autofocus,
    required this.hint,
    required this.onSubmit,
    required this.showEmojiButton,
    required this.showCameraButton,
    required this.showAttachmentButton,
    required this.emojiButtonLabel,
    required this.cameraButtonLabel,
    required this.attachmentButtonLabel,
    required this.attachmentIcon,
  });

  @override
  State<MessageTextFiled> createState() => _MessageTextFiledState();
}

class _MessageTextFiledState extends State<MessageTextFiled> {
  String txt = "";
  int lines = 1;

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_lineListener);
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_lineListener);
    super.dispose();
  }

  bool get isMultiLine => lines != 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
      children: [
        if (widget.showEmojiButton)
          Padding(
            padding: isMultiLine
                ? const EdgeInsets.only(bottom: 8)
                : EdgeInsets.zero,
            child: _InputActionButton(
              label: widget.emojiButtonLabel,
              onPressed: widget.onShowEmoji,
              icon: context.vInputTheme.emojiIcon!,
            ),
          ),
        if (widget.showEmojiButton) const SizedBox(width: 4),
        Expanded(
          child: AutoDirection(
            text: txt,
            child: CupertinoTextField(
              decoration: const BoxDecoration(color: Colors.transparent),
              placeholder: widget.hint,
              textCapitalization: TextCapitalization.sentences,
              controller: widget.textEditingController,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              onTap: widget.onInputTap,
              maxLines: 5,
              onChanged: (value) {
                setState(() {
                  txt = value;
                });
              },
              style: context.vInputTheme.textFieldTextStyle,
              minLines: 1,
              textAlignVertical: TextAlignVertical.top,
              onSubmitted: VPlatforms.isMobile
                  ? null
                  : (value) {
                      if (value.trim().isNotEmpty) {
                        widget.onSubmit(value);
                      }
                      widget.focusNode.requestFocus();
                    },
              textInputAction: VPlatforms.isMobile
                  ? TextInputAction.newline
                  : TextInputAction.send,
              keyboardType: VPlatforms.isMobile
                  ? TextInputType.multiline
                  : TextInputType.text,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Visibility(
          visible: !widget.isTyping,
          child: Padding(
            padding: isMultiLine
                ? const EdgeInsets.only(bottom: 8)
                : EdgeInsets.zero,
            child: Row(
              children: [
                if (VPlatforms.isMobile && widget.showCameraButton)
                  _InputActionButton(
                    label: widget.cameraButtonLabel,
                    onPressed: widget.onCameraPress,
                    icon: context.vInputTheme.cameraIcon!,
                  ),
                if (VPlatforms.isMobile && widget.showCameraButton)
                  const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        if (widget.showAttachmentButton)
          Padding(
            padding: isMultiLine
                ? const EdgeInsets.only(bottom: 8)
                : EdgeInsets.zero,
            child: _InputActionButton(
              label: widget.attachmentButtonLabel,
              onPressed: widget.onAttachFilePress,
              icon: widget.attachmentIcon,
            ),
          ),
      ],
    );
  }

  void _lineListener() {
    final count = widget.textEditingController.text.split('\n').length;
    if (lines != count) {
      setState(() {
        lines = count;
      });
    }
  }
}

class _InputActionButton extends StatelessWidget {
  const _InputActionButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: icon,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

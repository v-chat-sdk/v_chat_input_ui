// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:v_platform/v_platform.dart';

import 'v_attachment_theme_data.dart';
import 'v_emoji_picker_theme_data.dart';

class VInputTheme extends ThemeExtension<VInputTheme> {
  final BoxDecoration containerDecoration;
  final InputDecoration textFieldDecoration;

  Widget? cameraIcon;
  Widget? fileIcon;
  Widget? emojiIcon;
  Widget? trashIcon;

  Widget? recordBtn;
  Widget? sendBtn;
  final TextStyle textFieldTextStyle;
  final VAttachmentThemeData attachmentTheme;
  final VEmojiPickerThemeData emojiPickerTheme;

  /// Shared square extent for the Send and Record controls and the minimum
  /// height of the one-line input container.
  final double composerActionExtent;

  VInputTheme._({
    required this.containerDecoration,
    required this.textFieldDecoration,
    required this.recordBtn,
    required this.sendBtn,
    required this.textFieldTextStyle,
    required this.emojiIcon,
    required this.trashIcon,
    required this.fileIcon,
    required this.cameraIcon,
    required this.attachmentTheme,
    required this.emojiPickerTheme,
    required this.composerActionExtent,
  }) : assert(composerActionExtent > 0);

  VInputTheme.light({
    this.containerDecoration = const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),

    this.textFieldDecoration = const InputDecoration(
      border: InputBorder.none,
      fillColor: Colors.transparent,
    ),
    this.recordBtn,
    this.sendBtn,
    this.textFieldTextStyle = const TextStyle(height: 1.3),
    this.composerActionExtent = 48,
    VAttachmentThemeData? attachmentTheme,
    VEmojiPickerThemeData? emojiPickerTheme,
  }) : assert(composerActionExtent > 0),
       attachmentTheme = attachmentTheme ?? const VAttachmentThemeData.light(),
       emojiPickerTheme =
           emojiPickerTheme ?? const VEmojiPickerThemeData.light() {
    emojiIcon ??= const Icon(
      Icons.emoji_emotions_outlined,
      size: 26,
      color: Colors.green,
    );
    fileIcon ??= const Icon(
      CupertinoIcons.paperclip,
      size: 26,
      color: Colors.green,
    );
    cameraIcon ??= const Icon(
      CupertinoIcons.camera,
      size: 26,
      color: Colors.green,
    );
    trashIcon ??= const Icon(
      CupertinoIcons.trash,
      color: Colors.redAccent,
      size: 30,
    );
    recordBtn ??= Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VPlatforms.isDeskTop ? Colors.grey : Colors.green,
      ),
      child: const Icon(Icons.mic, color: Colors.white),
    );
    sendBtn ??= Container(
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
      ),
      child: const Icon(Icons.send, color: Colors.white),
    );
  }

  VInputTheme.dark({
    this.containerDecoration = const BoxDecoration(
      color: Color(0xf7232121),
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),

    this.textFieldDecoration = const InputDecoration(
      border: InputBorder.none,
      fillColor: Colors.transparent,
    ),
    this.recordBtn,
    this.textFieldTextStyle = const TextStyle(height: 1.3),
    this.sendBtn,
    this.composerActionExtent = 48,
    VAttachmentThemeData? attachmentTheme,
    VEmojiPickerThemeData? emojiPickerTheme,
  }) : assert(composerActionExtent > 0),
       attachmentTheme = attachmentTheme ?? const VAttachmentThemeData.dark(),
       emojiPickerTheme =
           emojiPickerTheme ?? const VEmojiPickerThemeData.dark() {
    emojiIcon ??= const Icon(
      CupertinoIcons.smiley,
      size: 26,
      color: Colors.green,
    );
    fileIcon ??= const Icon(
      CupertinoIcons.paperclip,
      size: 26,
      color: Colors.green,
    );
    cameraIcon ??= const Icon(
      CupertinoIcons.camera,
      size: 26,
      color: Colors.green,
    );
    trashIcon ??= const Icon(
      CupertinoIcons.trash,
      color: Colors.redAccent,
      size: 30,
    );
    recordBtn ??= Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VPlatforms.isDeskTop ? Colors.grey : Colors.green,
      ),
      child: const Icon(Icons.mic, color: Colors.white),
    );
    sendBtn ??= Container(
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
      ),
      child: const Icon(Icons.send, color: Colors.white),
    );
  }

  @override
  ThemeExtension<VInputTheme> lerp(
    ThemeExtension<VInputTheme>? other,
    double t,
  ) {
    if (other is! VInputTheme) {
      return this;
    }
    return VInputTheme._(
      containerDecoration:
          BoxDecoration.lerp(
            containerDecoration,
            other.containerDecoration,
            t,
          ) ??
          containerDecoration,
      textFieldDecoration: t < 0.5
          ? textFieldDecoration
          : other.textFieldDecoration,
      cameraIcon: t < 0.5 ? cameraIcon : other.cameraIcon,
      fileIcon: t < 0.5 ? fileIcon : other.fileIcon,
      trashIcon: t < 0.5 ? trashIcon : other.trashIcon,
      emojiIcon: t < 0.5 ? emojiIcon : other.emojiIcon,
      recordBtn: t < 0.5 ? recordBtn : other.recordBtn,
      sendBtn: t < 0.5 ? sendBtn : other.sendBtn,
      textFieldTextStyle:
          TextStyle.lerp(textFieldTextStyle, other.textFieldTextStyle, t) ??
          textFieldTextStyle,
      attachmentTheme: attachmentTheme.lerp(other.attachmentTheme, t),
      emojiPickerTheme: emojiPickerTheme.lerp(other.emojiPickerTheme, t),
      composerActionExtent:
          composerActionExtent +
          (other.composerActionExtent - composerActionExtent) * t,
    );
  }

  @override
  VInputTheme copyWith({
    BoxDecoration? containerDecoration,
    InputDecoration? textFieldDecoration,
    Widget? cameraIcon,
    Widget? fileIcon,
    Widget? emojiIcon,
    Widget? recordBtn,
    Widget? sendBtn,
    Widget? trashIcon,
    TextStyle? textFieldTextStyle,
    VAttachmentThemeData? attachmentTheme,
    VEmojiPickerThemeData? emojiPickerTheme,
    double? composerActionExtent,
  }) {
    return VInputTheme._(
      containerDecoration: containerDecoration ?? this.containerDecoration,
      textFieldDecoration: textFieldDecoration ?? this.textFieldDecoration,
      cameraIcon: cameraIcon ?? this.cameraIcon,
      fileIcon: fileIcon ?? this.fileIcon,
      trashIcon: trashIcon ?? this.trashIcon,
      emojiIcon: emojiIcon ?? this.emojiIcon,
      recordBtn: recordBtn ?? this.recordBtn,
      sendBtn: sendBtn ?? this.sendBtn,
      textFieldTextStyle: textFieldTextStyle ?? this.textFieldTextStyle,
      attachmentTheme: attachmentTheme ?? this.attachmentTheme,
      emojiPickerTheme: emojiPickerTheme ?? this.emojiPickerTheme,
      composerActionExtent: composerActionExtent ?? this.composerActionExtent,
    );
  }
}

extension VInputThemeExt on BuildContext {
  VInputTheme get vInputTheme {
    final materialTheme = Theme.of(this);
    final configuredTheme = materialTheme.extension<VInputTheme>();
    if (configuredTheme != null) {
      return configuredTheme;
    }
    if (materialTheme.brightness == Brightness.dark) {
      return VInputTheme.dark();
    }
    return VInputTheme.light();
  }
}

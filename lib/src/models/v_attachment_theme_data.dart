// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

@immutable
class VAttachmentThemeData {
  const VAttachmentThemeData.light({
    this.panelDecoration = const BoxDecoration(color: Color(0xFFF7F7F7)),
    this.actionDecoration = const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(16)),
      boxShadow: [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    this.labelStyle = const TextStyle(
      color: Color(0xFF202124),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    this.panelPadding = const EdgeInsets.fromLTRB(12, 16, 12, 12),
    this.actionPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.spacing = 12,
    this.runSpacing = 12,
    this.actionExtent = 84,
    this.maxPanelHeight = 320,
    this.launcherOpenIcon,
    this.launcherKeyboardIcon = const Icon(Icons.keyboard_alt_outlined),
  });

  const VAttachmentThemeData.dark({
    this.panelDecoration = const BoxDecoration(color: Color(0xFF171B1A)),
    this.actionDecoration = const BoxDecoration(
      color: Color(0xFF252B29),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      boxShadow: [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    this.labelStyle = const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    this.panelPadding = const EdgeInsets.fromLTRB(12, 16, 12, 12),
    this.actionPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.spacing = 12,
    this.runSpacing = 12,
    this.actionExtent = 84,
    this.maxPanelHeight = 320,
    this.launcherOpenIcon,
    this.launcherKeyboardIcon = const Icon(Icons.keyboard_alt_outlined),
  });

  const VAttachmentThemeData._({
    required this.panelDecoration,
    required this.actionDecoration,
    required this.labelStyle,
    required this.panelPadding,
    required this.actionPadding,
    required this.spacing,
    required this.runSpacing,
    required this.actionExtent,
    required this.maxPanelHeight,
    required this.launcherOpenIcon,
    required this.launcherKeyboardIcon,
  });

  final Decoration panelDecoration;
  final Decoration actionDecoration;
  final TextStyle labelStyle;
  final EdgeInsets panelPadding;
  final EdgeInsets actionPadding;
  final double spacing;
  final double runSpacing;
  final double actionExtent;
  final double maxPanelHeight;
  final Widget? launcherOpenIcon;
  final Widget? launcherKeyboardIcon;

  VAttachmentThemeData copyWith({
    Decoration? panelDecoration,
    Decoration? actionDecoration,
    TextStyle? labelStyle,
    EdgeInsets? panelPadding,
    EdgeInsets? actionPadding,
    double? spacing,
    double? runSpacing,
    double? actionExtent,
    double? maxPanelHeight,
    Widget? launcherOpenIcon,
    Widget? launcherKeyboardIcon,
  }) {
    return VAttachmentThemeData._(
      panelDecoration: panelDecoration ?? this.panelDecoration,
      actionDecoration: actionDecoration ?? this.actionDecoration,
      labelStyle: labelStyle ?? this.labelStyle,
      panelPadding: panelPadding ?? this.panelPadding,
      actionPadding: actionPadding ?? this.actionPadding,
      spacing: spacing ?? this.spacing,
      runSpacing: runSpacing ?? this.runSpacing,
      actionExtent: actionExtent ?? this.actionExtent,
      maxPanelHeight: maxPanelHeight ?? this.maxPanelHeight,
      launcherOpenIcon: launcherOpenIcon ?? this.launcherOpenIcon,
      launcherKeyboardIcon: launcherKeyboardIcon ?? this.launcherKeyboardIcon,
    );
  }

  VAttachmentThemeData lerp(VAttachmentThemeData other, double t) {
    return VAttachmentThemeData._(
      panelDecoration:
          Decoration.lerp(panelDecoration, other.panelDecoration, t) ??
          panelDecoration,
      actionDecoration:
          Decoration.lerp(actionDecoration, other.actionDecoration, t) ??
          actionDecoration,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t) ?? labelStyle,
      panelPadding:
          EdgeInsets.lerp(panelPadding, other.panelPadding, t) ?? panelPadding,
      actionPadding:
          EdgeInsets.lerp(actionPadding, other.actionPadding, t) ??
          actionPadding,
      spacing: spacing + (other.spacing - spacing) * t,
      runSpacing: runSpacing + (other.runSpacing - runSpacing) * t,
      actionExtent: actionExtent + (other.actionExtent - actionExtent) * t,
      maxPanelHeight:
          maxPanelHeight + (other.maxPanelHeight - maxPanelHeight) * t,
      launcherOpenIcon: t < 0.5 ? launcherOpenIcon : other.launcherOpenIcon,
      launcherKeyboardIcon: t < 0.5
          ? launcherKeyboardIcon
          : other.launcherKeyboardIcon,
    );
  }
}

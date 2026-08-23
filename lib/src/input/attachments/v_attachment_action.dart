// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

typedef VAttachmentActionCallback =
    FutureOr<void> Function(BuildContext context);

/// Describes one action that can be rendered by an attachment presentation.
sealed class VAttachmentAction {
  const VAttachmentAction({this.label, this.icon, this.semanticLabel});

  const factory VAttachmentAction.media({
    String? label,
    Widget? icon,
    String? semanticLabel,
  }) = VMediaAttachmentAction;

  const factory VAttachmentAction.camera({
    String? label,
    Widget? icon,
    String? semanticLabel,
  }) = VCameraAttachmentAction;

  const factory VAttachmentAction.files({
    String? label,
    Widget? icon,
    String? semanticLabel,
  }) = VFilesAttachmentAction;

  const factory VAttachmentAction.location({
    String? label,
    Widget? icon,
    String? semanticLabel,
  }) = VLocationAttachmentAction;

  const factory VAttachmentAction.custom({
    required String id,
    required String label,
    required Widget icon,
    required VAttachmentActionCallback onPressed,
    String? semanticLabel,
  }) = VCustomAttachmentAction;

  /// Stable identifier used for ordering, validation, and widget keys.
  String get id;

  /// Visible label. Built-in actions resolve a localized fallback at runtime.
  final String? label;

  /// Action icon. Built-in actions resolve a themed fallback at runtime.
  final Widget? icon;

  /// Accessibility label. Defaults to [label] after resolution.
  final String? semanticLabel;
}

final class VMediaAttachmentAction extends VAttachmentAction {
  const VMediaAttachmentAction({super.label, super.icon, super.semanticLabel});

  @override
  String get id => 'media';
}

final class VCameraAttachmentAction extends VAttachmentAction {
  const VCameraAttachmentAction({super.label, super.icon, super.semanticLabel});

  @override
  String get id => 'camera';
}

final class VFilesAttachmentAction extends VAttachmentAction {
  const VFilesAttachmentAction({super.label, super.icon, super.semanticLabel});

  @override
  String get id => 'files';
}

final class VLocationAttachmentAction extends VAttachmentAction {
  const VLocationAttachmentAction({
    super.label,
    super.icon,
    super.semanticLabel,
  });

  @override
  String get id => 'location';
}

final class VCustomAttachmentAction extends VAttachmentAction {
  const VCustomAttachmentAction({
    required this.id,
    required String super.label,
    required Widget super.icon,
    required this.onPressed,
    super.semanticLabel,
  }) : assert(id != '', 'A custom attachment action id cannot be empty.');

  @override
  final String id;

  final VAttachmentActionCallback onPressed;
}

// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../models/v_input_language.dart';
import 'v_attachment_action.dart';
import 'v_attachment_presentation.dart';

List<VAttachmentAction> resolveAttachmentActions({
  required List<VAttachmentAction>? configuredActions,
  required VAttachmentPresentation presentation,
  required VInputLanguage language,
  required bool enableCamera,
  required bool enableLocation,
}) {
  final source =
      configuredActions ??
      _defaultActions(
        presentation: presentation,
        enableCamera: enableCamera,
        enableLocation: enableLocation,
      );
  final seenIds = <String>{};
  final resolved = <VAttachmentAction>[];

  for (final action in source) {
    if (action.id.trim().isEmpty) {
      throw ArgumentError.value(
        action.id,
        'attachmentActions',
        'Attachment action ids cannot be empty.',
      );
    }
    if (!seenIds.add(action.id)) {
      throw ArgumentError.value(
        configuredActions,
        'attachmentActions',
        'Attachment action ids must be unique. Duplicate id: ${action.id}',
      );
    }
    if (action is VCameraAttachmentAction && !enableCamera) continue;
    if (action is VLocationAttachmentAction && !enableLocation) continue;
    resolved.add(_resolveBuiltInAction(action, language));
  }

  return List.unmodifiable(resolved);
}

List<VAttachmentAction> _defaultActions({
  required VAttachmentPresentation presentation,
  required bool enableCamera,
  required bool enableLocation,
}) {
  return [
    const VAttachmentAction.media(),
    if (presentation != VAttachmentPresentation.adaptiveActionSheet &&
        enableCamera)
      const VAttachmentAction.camera(),
    const VAttachmentAction.files(),
    if (enableLocation) const VAttachmentAction.location(),
  ];
}

VAttachmentAction _resolveBuiltInAction(
  VAttachmentAction action,
  VInputLanguage language,
) {
  return switch (action) {
    VMediaAttachmentAction() => VAttachmentAction.media(
      label: action.label ?? language.media,
      icon: action.icon ?? const Icon(Icons.photo_library_outlined),
      semanticLabel: action.semanticLabel ?? action.label ?? language.media,
    ),
    VCameraAttachmentAction() => VAttachmentAction.camera(
      label: action.label ?? language.camera,
      icon: action.icon ?? const Icon(Icons.camera_alt_outlined),
      semanticLabel: action.semanticLabel ?? action.label ?? language.camera,
    ),
    VFilesAttachmentAction() => VAttachmentAction.files(
      label: action.label ?? language.files,
      icon: action.icon ?? const Icon(Icons.insert_drive_file_outlined),
      semanticLabel: action.semanticLabel ?? action.label ?? language.files,
    ),
    VLocationAttachmentAction() => VAttachmentAction.location(
      label: action.label ?? language.location,
      icon: action.icon ?? const Icon(Icons.location_on_outlined),
      semanticLabel: action.semanticLabel ?? action.label ?? language.location,
    ),
    VCustomAttachmentAction() => action,
  };
}

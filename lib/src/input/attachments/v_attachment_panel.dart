// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/v_input_theme.dart';
import 'v_attachment_action.dart';
import 'v_attachment_presentation.dart';

class VAttachmentPanel extends StatelessWidget {
  const VAttachmentPanel({
    super.key,
    required this.actions,
    required this.layout,
    required this.controller,
    required this.semanticLabel,
    this.builder,
    this.includeSafeArea = true,
  });

  final List<VAttachmentAction> actions;
  final VAttachmentPanelLayout layout;
  final VAttachmentPresentationController controller;
  final String semanticLabel;
  final VAttachmentPanelBuilder? builder;
  final bool includeSafeArea;

  @override
  Widget build(BuildContext context) {
    final attachmentTheme = context.vInputTheme.attachmentTheme;
    final body =
        builder?.call(context, actions, controller) ??
        _BuiltInAttachmentPanel(
          actions: actions,
          layout: layout,
          controller: controller,
        );
    Widget result = Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: attachmentTheme.panelDecoration,
        child: Padding(padding: attachmentTheme.panelPadding, child: body),
      ),
    );
    if (includeSafeArea) {
      result = SafeArea(top: false, child: result);
    }
    return result;
  }
}

class _BuiltInAttachmentPanel extends StatelessWidget {
  const _BuiltInAttachmentPanel({
    required this.actions,
    required this.layout,
    required this.controller,
  });

  final List<VAttachmentAction> actions;
  final VAttachmentPanelLayout layout;
  final VAttachmentPresentationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = context.vInputTheme.attachmentTheme;
    switch (layout) {
      case VAttachmentPanelLayout.horizontalList:
        return SizedBox(
          height: theme.actionExtent + 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, _) => SizedBox(width: theme.spacing),
            itemBuilder: (context, index) => _AttachmentActionTile(
              action: actions[index],
              controller: controller,
            ),
          ),
        );
      case VAttachmentPanelLayout.grid:
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: theme.maxPanelHeight),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: theme.actionExtent + theme.spacing,
              mainAxisExtent: theme.actionExtent + 48,
              crossAxisSpacing: theme.spacing,
              mainAxisSpacing: theme.runSpacing,
            ),
            itemBuilder: (context, index) => _AttachmentActionTile(
              action: actions[index],
              controller: controller,
            ),
          ),
        );
      case VAttachmentPanelLayout.wrap:
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: theme.maxPanelHeight),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: theme.spacing,
              runSpacing: theme.runSpacing,
              children: [
                for (final action in actions)
                  _AttachmentActionTile(action: action, controller: controller),
              ],
            ),
          ),
        );
    }
  }
}

class _AttachmentActionTile extends StatelessWidget {
  const _AttachmentActionTile({required this.action, required this.controller});

  final VAttachmentAction action;
  final VAttachmentPresentationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = context.vInputTheme.attachmentTheme;
    final label = action.label ?? action.id;
    return SizedBox(
      width: theme.actionExtent,
      child: Semantics(
        button: true,
        label: action.semanticLabel ?? label,
        excludeSemantics: true,
        child: Tooltip(
          message: action.semanticLabel ?? label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: controller.isOpen
                  ? () => unawaited(controller.select(action))
                  : null,
              child: Padding(
                padding: theme.actionPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: theme.actionExtent * 0.68,
                      height: theme.actionExtent * 0.68,
                      alignment: Alignment.center,
                      decoration: theme.actionDecoration,
                      child: action.icon ?? const Icon(Icons.attach_file),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.labelStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

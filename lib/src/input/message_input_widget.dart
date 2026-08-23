// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:place_picker_v2/entities/localization_item.dart';
import 'package:place_picker_v2/place_picker.dart';
import 'package:v_chat_mention_controller/v_chat_mention_controller.dart';
import 'package:v_platform/v_platform.dart';

import '../enums.dart';
import '../models/models.dart';
import '../permission_manager.dart';
import '../recorder/record_widget.dart';
import '../v_widgets/app_pick.dart';
import '../v_widgets/extension.dart';
import '../v_widgets/v_app_alert.dart';
import '../v_widgets/v_circle_avatar.dart';
import 'attachments/v_attachment_action.dart';
import 'attachments/v_attachment_action_resolver.dart';
import 'attachments/v_attachment_panel.dart';
import 'attachments/v_attachment_presentation.dart';
import 'attachments/v_message_input_controller.dart';
import 'widgets/emoji_keyborad.dart';
import 'widgets/message_record_btn.dart';
import 'widgets/message_send_btn.dart';
import 'widgets/message_text_filed.dart';

/// Renders the composer at the bottom of a messages page.
class VMessageInputWidget extends StatefulWidget {
  /// Callback when the user sends text.
  final ValueChanged<String> onSubmitText;

  /// Callback when the user sends images, videos, or a mixed selection.
  final ValueChanged<List<VPlatformFile>> onSubmitMedia;

  /// Callback when the user sends files.
  final ValueChanged<List<VPlatformFile>> onSubmitFiles;

  /// Callback when the user sends a location.
  ///
  /// This is available only when [googleMapsApiKey] has a value.
  final ValueChanged<LocationMessageData> onSubmitLocation;

  /// Callback when the user submits a voice message.
  final ValueChanged<MessageVoiceData> onSubmitVoice;

  /// Callback when the user starts typing, recording, or stops activity.
  final ValueChanged<RoomTypingEnum> onTypingChange;

  /// Legacy attachment callback.
  ///
  /// When supplied, this callback takes precedence over every built-in
  /// [attachmentPresentation].
  final Future<AttachEnumRes?> Function()? onAttachIconPress;

  /// Builds a custom mention result.
  final Widget Function(MentionModel)? mentionItemBuilder;

  /// Searches for mentions after the user enters `@`.
  final Future<List<MentionModel>> Function(String)? onMentionSearch;

  /// Widget rendered when replying to a message.
  final Widget? replyWidget;

  /// Whether the input should request focus when first shown.
  final bool autofocus;

  /// Widget rendered instead of the composer when the chat is closed.
  final Widget? stopChatWidget;

  /// Maximum voice recording duration.
  final Duration maxRecordTime;

  /// Optional consumer-owned text-field focus node.
  final FocusNode? focusNode;

  /// Enables the built-in location action when provided.
  final String? googleMapsApiKey;

  /// Composer labels and accessibility strings.
  final VInputLanguage language;

  /// Google Maps localization key.
  final String googleMapsLangKey;

  /// Maximum selected media or file size in bytes.
  final int maxMediaSize;

  /// Whether to show the built-in emoji picker action.
  final bool enableEmojiPicker;

  /// Whether to show attachment launchers and presentations.
  final bool enableAttachments;

  /// Whether camera actions are available on supported platforms.
  final bool enableCamera;

  /// Whether voice recording is available on supported platforms.
  final bool enableVoiceRecording;

  /// How attachment actions are presented.
  final VAttachmentPresentation attachmentPresentation;

  /// Optional ordered attachment actions.
  ///
  /// Built-in defaults are resolved when this is omitted.
  final List<VAttachmentAction>? attachmentActions;

  /// Position of the attachment launcher relative to the input container.
  final VAttachmentLauncherPlacement attachmentLauncherPlacement;

  /// Layout used by modal and inline attachment panels.
  final VAttachmentPanelLayout? attachmentPanelLayout;

  /// Whether to show the standalone camera shortcut in the text field.
  final bool showCameraLauncher;

  /// Optional replacement body for modal and inline attachment panels.
  final VAttachmentPanelBuilder? attachmentPanelBuilder;

  /// Optional consumer-owned composer panel controller.
  final VMessageInputController? controller;

  /// Optional replacement for the visual content shown while recording.
  ///
  /// The package still owns recorder lifecycle, duration limits, submission,
  /// and cleanup. When omitted, the built-in recording widget is used.
  final VRecordingWidgetBuilder? recordingWidgetBuilder;

  const VMessageInputWidget({
    super.key,
    required this.onSubmitText,
    required this.onSubmitMedia,
    required this.onSubmitVoice,
    required this.onSubmitFiles,
    required this.onSubmitLocation,
    required this.onTypingChange,
    this.maxMediaSize = 50 * 1024 * 1024,
    this.replyWidget,
    this.autofocus = false,
    this.focusNode,
    this.mentionItemBuilder,
    this.maxRecordTime = const Duration(minutes: 30),
    this.onAttachIconPress,
    this.stopChatWidget,
    this.onMentionSearch,
    this.googleMapsApiKey,
    this.language = const VInputLanguage(),
    this.googleMapsLangKey = 'en',
    this.enableEmojiPicker = true,
    this.enableAttachments = true,
    this.enableCamera = true,
    this.enableVoiceRecording = true,
    this.attachmentPresentation = VAttachmentPresentation.adaptiveActionSheet,
    this.attachmentActions,
    this.attachmentLauncherPlacement = VAttachmentLauncherPlacement.insideInput,
    this.attachmentPanelLayout,
    this.showCameraLauncher = true,
    this.attachmentPanelBuilder,
    this.controller,
    this.recordingWidgetBuilder,
  });

  @override
  State<VMessageInputWidget> createState() => _VMessageInputWidgetState();
}

class _VMessageInputWidgetState extends State<VMessageInputWidget> {
  VComposerPanel _activePanel = VComposerPanel.none;
  VComposerPanel? _pendingPanel;
  bool _hasDraftText = false;
  bool _isRecording = false;
  RoomTypingEnum _reportedActivity = RoomTypingEnum.stop;
  List<VAttachmentAction> _visibleAttachmentActions = const [];
  int _surfaceTransitionGeneration = 0;
  int? _scheduledPendingGeneration;
  bool _isDispatchingAttachment = false;

  final _textEditingController = VChatTextMentionController();
  final _recordStateKey = GlobalKey<RecordWidgetState>();
  final _mentionsWithPhoto = <MentionModel>[];
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  late VMessageInputController _controller;
  late bool _ownsController;
  int _mentionSearchGeneration = 0;
  bool _showMentionList = false;

  bool get _isSendButtonEnabled => _hasDraftText || _isRecording;

  bool get _canRecord => widget.enableVoiceRecording && !VPlatforms.isDeskTop;

  bool get _canShowAttachmentLauncher =>
      widget.enableAttachments && !_isRecording;

  bool get _usesInlineAttachments =>
      widget.onAttachIconPress == null &&
      widget.attachmentPresentation == VAttachmentPresentation.inlineTray;

  bool get _isInlineAttachmentOpen =>
      _usesInlineAttachments &&
      (_activePanel == VComposerPanel.attachments ||
          _pendingPanel == VComposerPanel.attachments);

  bool get _hasInterceptablePanel {
    if (_activePanel == VComposerPanel.emoji ||
        _pendingPanel == VComposerPanel.emoji) {
      return true;
    }
    return _isInlineAttachmentOpen;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;
    _attachController(widget.controller);
    _textEditingController.addListener(_textEditListener);
    _configureMentionSearch();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant VMessageInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode.addListener(_handleFocusChange);
    }
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController(widget.controller);
    }
    if (oldWidget.onMentionSearch != widget.onMentionSearch) {
      _configureMentionSearch();
    }
    if (oldWidget.stopChatWidget == null && widget.stopChatWidget != null) {
      _resetComposer();
    }
    if ((!widget.enableEmojiPicker &&
            (_activePanel == VComposerPanel.emoji ||
                _pendingPanel == VComposerPanel.emoji)) ||
        (!widget.enableAttachments &&
            (_activePanel == VComposerPanel.attachments ||
                _pendingPanel == VComposerPanel.attachments)) ||
        (oldWidget.attachmentPresentation != widget.attachmentPresentation &&
            (_activePanel == VComposerPanel.attachments ||
                _pendingPanel == VComposerPanel.attachments)) ||
        (oldWidget.onAttachIconPress != widget.onAttachIconPress &&
            (_activePanel == VComposerPanel.attachments ||
                _pendingPanel == VComposerPanel.attachments))) {
      _clearPanelState();
    }
    final attachmentConfigurationChanged =
        oldWidget.attachmentActions != widget.attachmentActions ||
        oldWidget.language != widget.language ||
        oldWidget.enableCamera != widget.enableCamera ||
        oldWidget.googleMapsApiKey != widget.googleMapsApiKey;
    if (attachmentConfigurationChanged &&
        widget.enableAttachments &&
        _usesInlineAttachments &&
        (_activePanel == VComposerPanel.attachments ||
            _pendingPanel == VComposerPanel.attachments)) {
      final actions = _resolvedAttachmentActions();
      if (actions.isEmpty) {
        _clearPanelState();
      } else {
        _visibleAttachmentActions = actions;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _activatePendingPanelWhenReady(MediaQuery.viewInsetsOf(context).bottom);
    if (widget.stopChatWidget != null) {
      return widget.stopChatWidget!;
    }

    return PopScope<Object?>(
      canPop: !_hasInterceptablePanel,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasInterceptablePanel) {
          _closePanel();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildComposerRow(context),
          ),
          _buildComposerSurface(context),
        ],
      ),
    );
  }

  Widget _buildComposerRow(BuildContext context) {
    final placement = widget.attachmentLauncherPlacement;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_canShowAttachmentLauncher &&
            placement == VAttachmentLauncherPlacement.leadingOutside) ...[
          _buildAttachmentLauncher(context),
          const SizedBox(width: 5),
        ],
        Expanded(child: _buildInputContainer(context)),
        if (_canShowAttachmentLauncher &&
            placement == VAttachmentLauncherPlacement.trailingOutside) ...[
          const SizedBox(width: 5),
          _buildAttachmentLauncher(context),
        ],
        if (_isSendButtonEnabled || _canRecord) const SizedBox(width: 5),
        if (_isSendButtonEnabled)
          MessageSendBtn(
            semanticLabel: widget.language.sendButtonLabel,
            onSend: _submitCurrentValue,
          )
        else if (_canRecord)
          MessageRecordBtn(
            semanticLabel: widget.language.recordButtonLabel,
            onRecordClick: _requestRecording,
          ),
      ],
    );
  }

  Widget _buildInputContainer(BuildContext context) {
    final theme = context.vInputTheme;
    return Container(
      key: const ValueKey('v_message_input_container'),
      constraints: BoxConstraints(minHeight: theme.composerActionExtent),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: theme.containerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_showMentionList) _buildMentionList(),
          if (widget.replyWidget != null) widget.replyWidget!,
          if (_isRecording)
            RecordWidget(
              key: _recordStateKey,
              onMaxTime: _finishRecording,
              maxTime: widget.maxRecordTime,
              cancelRecordingLabel: widget.language.cancelRecordingButtonLabel,
              onCancel: () => _setRecording(false),
              builder: widget.recordingWidgetBuilder,
            )
          else
            MessageTextFiled(
              autofocus: widget.autofocus,
              focusNode: _focusNode,
              hint: widget.language.textFieldHint,
              isTyping: _hasDraftText,
              onSubmit: (_) => _submitCurrentValue(),
              textEditingController: _textEditingController,
              onShowEmoji: _onEmojiPressed,
              onAttachFilePress: _onAttachmentLauncherPressed,
              onCameraPress: () => unawaited(
                _dispatchAttachmentAction(const VAttachmentAction.camera()),
              ),
              onInputTap: _handleInputTap,
              showEmojiButton: widget.enableEmojiPicker,
              showCameraButton:
                  widget.enableCamera && widget.showCameraLauncher,
              showAttachmentButton:
                  _canShowAttachmentLauncher &&
                  widget.attachmentLauncherPlacement ==
                      VAttachmentLauncherPlacement.insideInput,
              emojiButtonLabel: widget.language.emojiButtonLabel,
              cameraButtonLabel: widget.language.cameraButtonLabel,
              attachmentButtonLabel: _isInlineAttachmentOpen
                  ? widget.language.returnToKeyboardButtonLabel
                  : widget.language.openAttachmentsButtonLabel,
              attachmentIcon: _attachmentLauncherIcon(context),
            ),
        ],
      ),
    );
  }

  Widget _buildMentionList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: _mentionsWithPhoto.length,
        itemBuilder: (context, index) {
          final mention = _mentionsWithPhoto[index];
          void addMention() {
            _textEditingController.addMention(
              MentionData(id: mention.peerId, display: mention.name),
            );
          }

          if (widget.mentionItemBuilder != null) {
            return GestureDetector(
              onTap: addMention,
              child: widget.mentionItemBuilder!(mention),
            );
          }
          return CupertinoListTile(
            leading: VCircleAvatar(fullUrl: mention.imageS3, radius: 20),
            padding: EdgeInsets.zero,
            onTap: addMention,
            title: Text(mention.name),
          );
        },
      ),
    );
  }

  Widget _buildAttachmentLauncher(BuildContext context) {
    return IconButton(
      key: const ValueKey('v_attachment_launcher'),
      tooltip: _isInlineAttachmentOpen
          ? widget.language.returnToKeyboardButtonLabel
          : widget.language.openAttachmentsButtonLabel,
      onPressed: _onAttachmentLauncherPressed,
      icon: _attachmentLauncherIcon(context),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Widget _attachmentLauncherIcon(BuildContext context) {
    final attachmentTheme = context.vInputTheme.attachmentTheme;
    if (_isInlineAttachmentOpen) {
      return attachmentTheme.launcherKeyboardIcon ??
          const Icon(Icons.keyboard_alt_outlined);
    }
    return attachmentTheme.launcherOpenIcon ??
        context.vInputTheme.fileIcon ??
        const Icon(CupertinoIcons.paperclip);
  }

  Widget _buildComposerSurface(BuildContext context) {
    final Widget child;
    if (_activePanel == VComposerPanel.emoji) {
      child = EmojiKeyboard(
        key: const ValueKey(VComposerPanel.emoji),
        controller: _textEditingController,
        isEmojiShowing: true,
      );
    } else if (_activePanel == VComposerPanel.attachments &&
        _usesInlineAttachments) {
      child = VAttachmentPanel(
        key: const ValueKey(VComposerPanel.attachments),
        actions: _visibleAttachmentActions,
        layout:
            widget.attachmentPanelLayout ??
            VAttachmentPanelLayout.horizontalList,
        controller: _inlinePanelController,
        semanticLabel: widget.language.attachmentPanelLabel,
        builder: widget.attachmentPanelBuilder,
      );
    } else {
      child = const SizedBox.shrink(key: ValueKey(VComposerPanel.none));
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        child: child,
      ),
    );
  }

  VAttachmentPresentationController get _inlinePanelController =>
      _AttachmentPanelController(
        isPanelOpen: () =>
            mounted &&
            _activePanel == VComposerPanel.attachments &&
            _usesInlineAttachments,
        selectAction: _dispatchAttachmentAction,
        closePanel: _closePanel,
        showComposerKeyboard: _showKeyboard,
      );

  void _onEmojiPressed() {
    if (_activePanel == VComposerPanel.emoji ||
        _pendingPanel == VComposerPanel.emoji) {
      _showKeyboard();
      return;
    }
    _requestPanel(VComposerPanel.emoji);
  }

  void _onAttachmentLauncherPressed() {
    if (_isInlineAttachmentOpen) {
      _showKeyboard();
      return;
    }
    unawaited(_showAttachments());
  }

  Future<void> _showAttachments() {
    if (!widget.enableAttachments || widget.stopChatWidget != null) {
      return Future.value();
    }
    if (widget.onAttachIconPress != null) {
      _prepareForExternalPresentation();
      return _showLegacyAttachment();
    }

    switch (widget.attachmentPresentation) {
      case VAttachmentPresentation.inlineTray:
        final actions = _resolvedAttachmentActions();
        if (actions.isEmpty) {
          _prepareForExternalPresentation();
          return Future.value();
        }
        _requestPanel(VComposerPanel.attachments, attachmentActions: actions);
        return Future.value();
      case VAttachmentPresentation.adaptiveActionSheet:
        _prepareForExternalPresentation();
        return _showAdaptiveAttachmentSheet();
      case VAttachmentPresentation.modalBottomSheet:
        _prepareForExternalPresentation();
        return _showAttachmentBottomSheet();
    }
  }

  Future<void> _showLegacyAttachment() async {
    if (_isDispatchingAttachment) return;
    _isDispatchingAttachment = true;
    try {
      final result = await widget.onAttachIconPress!();
      if (result != null && mounted) {
        await _dispatchLegacyAttachment(result, alreadyLocked: true);
      }
    } finally {
      _isDispatchingAttachment = false;
    }
  }

  Future<void> _showAdaptiveAttachmentSheet() async {
    final actions = _resolvedAttachmentActions();
    if (actions.isEmpty || !mounted) return;
    final result = await VAppAlert.showModalSheet<VAttachmentAction>(
      content: [
        for (final action in actions)
          ModelSheetItem<VAttachmentAction>(
            title: action.label ?? action.id,
            id: action,
            iconData: action.icon is Icon ? action.icon! as Icon : null,
          ),
      ],
      context: context,
      title: widget.language.shareMediaAndLocation,
      cancelText: widget.language.cancel,
    );
    if (result != null && mounted) {
      await _dispatchAttachmentAction(result.id);
    }
  }

  Future<void> _showAttachmentBottomSheet() async {
    final actions = _resolvedAttachmentActions();
    if (actions.isEmpty || !mounted) return;
    var isOpen = true;
    var returnToKeyboard = false;
    BuildContext? sheetContext;
    late final _AttachmentPanelController panelController;
    panelController = _AttachmentPanelController(
      isPanelOpen: () => isOpen,
      selectAction: (action) async {
        final currentContext = sheetContext;
        if (!isOpen || currentContext == null) return;
        isOpen = false;
        Navigator.of(currentContext).pop(action);
      },
      closePanel: () {
        final currentContext = sheetContext;
        if (!isOpen || currentContext == null) return;
        isOpen = false;
        Navigator.of(currentContext).pop();
      },
      showComposerKeyboard: () {
        final currentContext = sheetContext;
        if (!isOpen || currentContext == null) return;
        returnToKeyboard = true;
        isOpen = false;
        Navigator.of(currentContext).pop();
      },
    );

    final selected = await showModalBottomSheet<VAttachmentAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (context) {
        sheetContext = context;
        return VAttachmentPanel(
          actions: actions,
          layout: widget.attachmentPanelLayout ?? VAttachmentPanelLayout.grid,
          controller: panelController,
          semanticLabel: widget.language.attachmentPanelLabel,
          builder: widget.attachmentPanelBuilder,
        );
      },
    );
    isOpen = false;
    if (!mounted) return;
    if (returnToKeyboard) {
      _showKeyboard();
    } else if (selected != null) {
      await _dispatchAttachmentAction(selected);
    }
  }

  List<VAttachmentAction> _resolvedAttachmentActions() {
    return resolveAttachmentActions(
      configuredActions: widget.attachmentActions,
      presentation: widget.attachmentPresentation,
      language: widget.language,
      enableCamera: widget.enableCamera,
      enableLocation: widget.googleMapsApiKey != null,
    );
  }

  void _requestPanel(
    VComposerPanel panel, {
    List<VAttachmentAction> attachmentActions = const [],
  }) {
    if (widget.stopChatWidget != null ||
        (panel == VComposerPanel.emoji && !widget.enableEmojiPicker) ||
        (panel == VComposerPanel.attachments &&
            (!widget.enableAttachments || !_usesInlineAttachments))) {
      return;
    }
    final generation = ++_surfaceTransitionGeneration;
    _scheduledPendingGeneration = null;
    _focusNode.unfocus();
    final waitsForKeyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    setState(() {
      _activePanel = waitsForKeyboard ? VComposerPanel.none : panel;
      _pendingPanel = waitsForKeyboard ? panel : null;
      _visibleAttachmentActions = panel == VComposerPanel.attachments
          ? attachmentActions
          : const [];
    });
    _controller.updateActivePanel(this, _activePanel);
    if (!waitsForKeyboard) {
      _scheduledPendingGeneration = generation;
    }
  }

  void _activatePendingPanelWhenReady(double keyboardInset) {
    final pendingPanel = _pendingPanel;
    if (pendingPanel == null || keyboardInset > 0) return;
    final generation = _surfaceTransitionGeneration;
    if (_scheduledPendingGeneration == generation) return;
    _scheduledPendingGeneration = generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _surfaceTransitionGeneration ||
          _pendingPanel != pendingPanel ||
          MediaQuery.viewInsetsOf(context).bottom > 0) {
        return;
      }
      setState(() {
        _pendingPanel = null;
        _activePanel = pendingPanel;
      });
      _controller.updateActivePanel(this, pendingPanel);
    });
  }

  void _prepareForExternalPresentation() {
    _focusNode.unfocus();
    _clearPanelState();
  }

  void _showKeyboard() {
    final generation = ++_surfaceTransitionGeneration;
    _clearPanelState(incrementGeneration: false);
    _focusNode.canRequestFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _surfaceTransitionGeneration ||
          widget.stopChatWidget != null) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  void _handleInputTap() {
    ++_surfaceTransitionGeneration;
    _clearPanelState(incrementGeneration: false);
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _closePanel() {
    _clearPanelState();
  }

  void _clearPanelState({bool incrementGeneration = true}) {
    if (incrementGeneration) ++_surfaceTransitionGeneration;
    _scheduledPendingGeneration = null;
    if (_activePanel == VComposerPanel.none && _pendingPanel == null) return;
    if (mounted) {
      setState(() {
        _activePanel = VComposerPanel.none;
        _pendingPanel = null;
        _visibleAttachmentActions = const [];
      });
    } else {
      _activePanel = VComposerPanel.none;
      _pendingPanel = null;
      _visibleAttachmentActions = const [];
    }
    _controller.updateActivePanel(this, VComposerPanel.none);
  }

  Future<void> _dispatchAttachmentAction(VAttachmentAction action) async {
    if (_isDispatchingAttachment) return;
    _isDispatchingAttachment = true;
    _closePanel();
    try {
      switch (action) {
        case VMediaAttachmentAction():
          await _pickMedia();
          return;
        case VCameraAttachmentAction():
          await _dispatchCamera();
          return;
        case VFilesAttachmentAction():
          await _pickFiles();
          return;
        case VLocationAttachmentAction():
          await _pickLocation();
          return;
        case VCustomAttachmentAction():
          if (mounted) {
            await Future<void>.sync(() => action.onPressed(context));
          }
          return;
      }
    } finally {
      _isDispatchingAttachment = false;
    }
  }

  Future<void> _dispatchLegacyAttachment(
    AttachEnumRes result, {
    bool alreadyLocked = false,
  }) async {
    if (!alreadyLocked && _isDispatchingAttachment) return;
    if (!alreadyLocked) _isDispatchingAttachment = true;
    _closePanel();
    try {
      switch (result) {
        case AttachEnumRes.media:
          await _pickMedia();
          return;
        case AttachEnumRes.files:
          await _pickFiles();
          return;
        case AttachEnumRes.location:
          await _pickLocation();
          return;
      }
    } finally {
      if (!alreadyLocked) _isDispatchingAttachment = false;
    }
  }

  Future<void> _pickMedia() async {
    final result = await VAppPick.getMedia(maxFileSize: widget.maxMediaSize);
    if (result == null || !mounted) return;
    if (result.oversizedCount > 0) {
      VAppAlert.showErrorSnackBar(
        msg: widget.language.thereIsVideoSizeBiggerThanAllowedSize,
        context: context,
      );
    }
    if (result.files.isNotEmpty) {
      widget.onSubmitMedia(result.files);
    }
  }

  Future<void> _pickFiles() async {
    final result = await VAppPick.getFiles(maxFileSize: widget.maxMediaSize);
    if (result == null || !mounted) return;
    if (result.oversizedCount > 0) {
      VAppAlert.showErrorSnackBar(
        msg: widget.language.thereIsFileHasSizeBiggerThanAllowedSize,
        context: context,
      );
    }
    if (result.files.isNotEmpty) {
      widget.onSubmitFiles(result.files);
    }
  }

  Future<void> _pickLocation() async {
    final apiKey = widget.googleMapsApiKey;
    if (apiKey == null || !mounted) return;
    final result = await context.toPage<LocationResult?>(
      PlacePicker(
        apiKey,
        localizationItem: LocalizationItem(
          languageCode: widget.googleMapsLangKey,
        ),
      ),
    );
    if (!mounted || result == null || result.latLng == null) return;
    final latitude = result.latLng!.latitude;
    final longitude = result.latLng!.longitude;
    widget.onSubmitLocation(
      LocationMessageData(
        latLng: LatLng(latitude, longitude),
        linkPreviewData: LinkPreviewData(
          title: result.name,
          desc: result.formattedAddress,
          link: 'https://maps.google.com/?q=$latitude,$longitude',
        ),
      ),
    );
  }

  Future<void> _dispatchCamera() async {
    if (!widget.enableCamera) return;
    _closePanel();
    final isCameraAllowed = await PermissionManager.isCameraAllowed();
    if (!mounted) return;
    if (!isCameraAllowed) {
      final permissionGranted = await PermissionManager.askForCamera();
      if (!mounted || !permissionGranted) return;
    }
    final entity = await VAppPick.pickFromWeAssetCamera(
      onXFileCaptured: (file, _) {
        if (!mounted) return false;
        Navigator.pop(context);
        widget.onSubmitMedia([
          VPlatformFile.fromPath(fileLocalPath: file.path),
        ]);
        return true;
      },
      context: context,
    );
    if (!mounted || entity == null) return;
    widget.onSubmitMedia([entity]);
  }

  Future<void> _requestRecording() async {
    _closePanel();
    var isAllowed = await PermissionManager.isAllowRecord();
    if (!mounted) return;
    if (!isAllowed) {
      isAllowed = await PermissionManager.askForRecord();
    }
    if (mounted && isAllowed) {
      _setRecording(true);
    }
  }

  Future<void> _finishRecording() async {
    final recordState = _recordStateKey.currentState;
    if (recordState == null) return;
    widget.onSubmitVoice(await recordState.stopRecord());
    if (mounted) _setRecording(false);
  }

  Future<void> _submitCurrentValue() async {
    if (_isRecording) {
      await _finishRecording();
      return;
    }
    if (!_hasDraftText || _textEditingController.text.trim().isEmpty) return;
    widget.onSubmitText(_textEditingController.markupText);
    _textEditingController.clear();
  }

  Future<void> _handleMentionSearch(String? value) async {
    final generation = ++_mentionSearchGeneration;
    final search = widget.onMentionSearch;
    if (value == null || search == null) {
      if (mounted && (_showMentionList || _mentionsWithPhoto.isNotEmpty)) {
        setState(() {
          _mentionsWithPhoto.clear();
          _showMentionList = false;
        });
      }
      return;
    }

    List<MentionModel> results;
    try {
      results = await search(value);
    } catch (_) {
      results = const [];
    }
    if (!mounted || generation != _mentionSearchGeneration) return;
    setState(() {
      _mentionsWithPhoto
        ..clear()
        ..addAll(results);
      _showMentionList = results.isNotEmpty;
    });
  }

  void _configureMentionSearch() {
    _textEditingController.onSearch = widget.onMentionSearch == null
        ? null
        : _handleMentionSearch;
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus &&
        (_activePanel != VComposerPanel.none || _pendingPanel != null)) {
      _clearPanelState();
    }
  }

  void _textEditListener() {
    final hasDraftText = _textEditingController.text.isNotEmpty;
    if (mounted && hasDraftText != _hasDraftText) {
      setState(() {
        _hasDraftText = hasDraftText;
      });
    } else {
      _hasDraftText = hasDraftText;
    }
    _updateReportedActivity();
  }

  void _setRecording(bool value) {
    if (_isRecording == value) return;
    setState(() {
      _isRecording = value;
    });
    _updateReportedActivity();
  }

  void _updateReportedActivity() {
    final nextActivity = _isRecording
        ? RoomTypingEnum.recording
        : _hasDraftText
        ? RoomTypingEnum.typing
        : RoomTypingEnum.stop;
    if (nextActivity == _reportedActivity) return;
    _reportedActivity = nextActivity;
    widget.onTypingChange(nextActivity);
  }

  void _resetComposer() {
    ++_mentionSearchGeneration;
    ++_surfaceTransitionGeneration;
    _scheduledPendingGeneration = null;
    _textEditingController.removeListener(_textEditListener);
    _textEditingController.clear();
    _textEditingController.addListener(_textEditListener);
    _hasDraftText = false;
    _isRecording = false;
    _activePanel = VComposerPanel.none;
    _pendingPanel = null;
    _visibleAttachmentActions = const [];
    _showMentionList = false;
    _mentionsWithPhoto.clear();
    _controller.updateActivePanel(this, VComposerPanel.none);
    if (_reportedActivity != RoomTypingEnum.stop) {
      _reportedActivity = RoomTypingEnum.stop;
      widget.onTypingChange(RoomTypingEnum.stop);
    }
  }

  void _attachController(VMessageInputController? controller) {
    _controller = controller ?? VMessageInputController();
    _ownsController = controller == null;
    _controller.attach(
      owner: this,
      showAttachments: () => unawaited(_showAttachments()),
      showEmoji: () => _requestPanel(VComposerPanel.emoji),
      showKeyboard: _showKeyboard,
      closePanel: _closePanel,
    );
    _controller.updateActivePanel(this, _activePanel);
  }

  void _detachController() {
    _controller.updateActivePanel(this, VComposerPanel.none);
    _controller.detach(this);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  @override
  void dispose() {
    ++_mentionSearchGeneration;
    ++_surfaceTransitionGeneration;
    if (_reportedActivity != RoomTypingEnum.stop) {
      widget.onTypingChange(RoomTypingEnum.stop);
    }
    _textEditingController.removeListener(_textEditListener);
    _textEditingController.onSearch = null;
    _textEditingController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _detachController();
    super.dispose();
  }
}

class _AttachmentPanelController implements VAttachmentPresentationController {
  const _AttachmentPanelController({
    required this.isPanelOpen,
    required this.selectAction,
    required this.closePanel,
    required this.showComposerKeyboard,
  });

  final bool Function() isPanelOpen;
  final Future<void> Function(VAttachmentAction action) selectAction;
  final VoidCallback closePanel;
  final VoidCallback showComposerKeyboard;

  @override
  bool get isOpen => isPanelOpen();

  @override
  Future<void> select(VAttachmentAction action) => selectAction(action);

  @override
  void close() => closePanel();

  @override
  void showKeyboard() => showComposerKeyboard();
}

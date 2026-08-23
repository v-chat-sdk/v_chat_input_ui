import 'package:flutter/material.dart';
import 'package:v_chat_input_ui/v_chat_input_ui.dart';

void main() {
  runApp(const VChatInputExampleApp());
}

class VChatInputExampleApp extends StatefulWidget {
  const VChatInputExampleApp({super.key});

  @override
  State<VChatInputExampleApp> createState() => _VChatInputExampleAppState();
}

class _VChatInputExampleAppState extends State<VChatInputExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'V Chat Input UI',
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: ChatComposerDemo(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.light
                ? ThemeMode.dark
                : ThemeMode.light;
          });
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF18A779),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF111816)
          : const Color(0xFFF2F7F5),
      extensions: [
        isDark
            ? VInputTheme.dark(
                containerDecoration: BoxDecoration(
                  color: const Color(0xFF202A27),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                textFieldTextStyle: const TextStyle(
                  height: 1.35,
                  color: Colors.white,
                ),
                attachmentTheme: VAttachmentThemeData.dark(
                  panelDecoration: const BoxDecoration(
                    color: Color(0xFF17211E),
                    border: Border(top: BorderSide(color: Color(0xFF33433E))),
                  ),
                  actionDecoration: BoxDecoration(
                    color: const Color(0xFF26332F),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  launcherOpenIcon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF5EE0B6),
                  ),
                  launcherKeyboardIcon: const Icon(
                    Icons.keyboard_alt_outlined,
                    color: Color(0xFF5EE0B6),
                  ),
                ),
              )
            : VInputTheme.light(
                containerDecoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD8E6E1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120C5B43),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                textFieldTextStyle: const TextStyle(
                  height: 1.35,
                  color: Color(0xFF15231F),
                ),
                attachmentTheme: VAttachmentThemeData.light(
                  panelDecoration: const BoxDecoration(
                    color: Color(0xFFF8FCFA),
                    border: Border(top: BorderSide(color: Color(0xFFD8E6E1))),
                  ),
                  actionDecoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD8E6E1)),
                  ),
                  launcherOpenIcon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF128A66),
                  ),
                  launcherKeyboardIcon: const Icon(
                    Icons.keyboard_alt_outlined,
                    color: Color(0xFF128A66),
                  ),
                ),
              ),
      ],
    );
  }
}

class ChatComposerDemo extends StatefulWidget {
  const ChatComposerDemo({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<ChatComposerDemo> createState() => _ChatComposerDemoState();
}

class _ChatComposerDemoState extends State<ChatComposerDemo> {
  final _messages = <_DemoMessage>[
    const _DemoMessage(
      text: 'Welcome! This example uses the real VMessageInputWidget below.',
      time: '10:24',
    ),
    const _DemoMessage(
      text: 'Try text, emoji, attachments, @mentions, or a voice note.',
      time: '10:25',
    ),
    const _DemoMessage(
      text: 'Everything is customizable through VInputTheme.',
      time: '10:26',
      isMine: true,
    ),
  ];
  RoomTypingEnum _typingState = RoomTypingEnum.stop;
  VAttachmentPresentation _attachmentPresentation =
      VAttachmentPresentation.inlineTray;
  VAttachmentLauncherPlacement _launcherPlacement =
      VAttachmentLauncherPlacement.leadingOutside;
  VAttachmentPanelLayout _panelLayout = VAttachmentPanelLayout.grid;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            _BrandMark(),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'V Chat Input UI',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Interactive package example',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Use light theme' : 'Use dark theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    children: [
                      const _FeatureBanner(),
                      const SizedBox(height: 18),
                      _ComposerControls(
                        presentation: _attachmentPresentation,
                        launcherPlacement: _launcherPlacement,
                        panelLayout: _panelLayout,
                        onPresentationChanged: (value) {
                          setState(() => _attachmentPresentation = value);
                        },
                        onLauncherPlacementChanged: (value) {
                          setState(() => _launcherPlacement = value);
                        },
                        onPanelLayoutChanged: (value) {
                          setState(() => _panelLayout = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      ..._messages.map(
                        (message) => _MessageBubble(message: message),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _typingState == RoomTypingEnum.stop
                      ? const SizedBox(height: 22)
                      : Align(
                          key: ValueKey(_typingState),
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              _typingState == RoomTypingEnum.recording
                                  ? 'Recording a voice message…'
                                  : 'Composing a message…',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                ),
                VMessageInputWidget(
                  maxRecordTime: const Duration(seconds: 30),
                  recordingWidgetBuilder: (context, state, onCancel) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: state.progress,
                              minHeight: 3,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            state.elapsedLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            tooltip: state.cancelLabel,
                            onPressed: onCancel,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    );
                  },
                  attachmentPresentation: _attachmentPresentation,
                  attachmentLauncherPlacement: _launcherPlacement,
                  attachmentPanelLayout: _panelLayout,
                  attachmentActions: [
                    const VAttachmentAction.media(),
                    const VAttachmentAction.camera(),
                    const VAttachmentAction.files(),
                    VAttachmentAction.custom(
                      id: 'poll',
                      label: 'Poll',
                      semanticLabel: 'Create a poll',
                      icon: const Icon(Icons.poll_outlined),
                      onPressed: (_) {
                        _showSelection(
                          'Poll is a consumer-owned custom action',
                        );
                      },
                    ),
                  ],
                  onSubmitText: (message) {
                    setState(() {
                      _messages.add(
                        _DemoMessage(
                          text: message,
                          time: _currentTime(),
                          isMine: true,
                        ),
                      );
                    });
                  },
                  onSubmitMedia: (files) => _showSelection(
                    '${files.length} media item${files.length == 1 ? '' : 's'} selected',
                  ),
                  onSubmitFiles: (files) => _showSelection(
                    '${files.length} file${files.length == 1 ? '' : 's'} selected',
                  ),
                  onSubmitLocation: (_) => _showSelection('Location selected'),
                  onSubmitVoice: (voice) {
                    final seconds = voice.durationObj.inSeconds;
                    setState(() {
                      _messages.add(
                        _DemoMessage(
                          text: 'Voice message • ${seconds}s',
                          time: _currentTime(),
                          isMine: true,
                          isVoice: true,
                        ),
                      );
                    });
                  },
                  onTypingChange: (typing) {
                    if (!mounted || typing == _typingState) return;
                    setState(() {
                      _typingState = typing;
                    });
                  },
                  onMentionSearch: (query) async {
                    const people = [
                      MentionModel(
                        peerId: 'alex',
                        name: 'Alex Morgan',
                        image: 'https://i.pravatar.cc/120?img=12',
                      ),
                      MentionModel(
                        peerId: 'sam',
                        name: 'Sam Wilson',
                        image: 'https://i.pravatar.cc/120?img=5',
                      ),
                    ];
                    final normalized = query.toLowerCase();
                    return people
                        .where(
                          (person) =>
                              person.name.toLowerCase().contains(normalized),
                        )
                        .toList();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSelection(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _currentTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    return '$hour:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _ComposerControls extends StatelessWidget {
  const _ComposerControls({
    required this.presentation,
    required this.launcherPlacement,
    required this.panelLayout,
    required this.onPresentationChanged,
    required this.onLauncherPlacementChanged,
    required this.onPanelLayoutChanged,
  });

  final VAttachmentPresentation presentation;
  final VAttachmentLauncherPlacement launcherPlacement;
  final VAttachmentPanelLayout panelLayout;
  final ValueChanged<VAttachmentPresentation> onPresentationChanged;
  final ValueChanged<VAttachmentLauncherPlacement> onLauncherPlacementChanged;
  final ValueChanged<VAttachmentPanelLayout> onPanelLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachment playground',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Switch presentation, launcher placement, and panel layout while keeping the same typed actions.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          _ControlGroup(
            label: 'Presentation',
            children: [
              _choice(
                label: 'Action sheet',
                selected:
                    presentation == VAttachmentPresentation.adaptiveActionSheet,
                onSelected: () => onPresentationChanged(
                  VAttachmentPresentation.adaptiveActionSheet,
                ),
              ),
              _choice(
                label: 'Bottom sheet',
                selected:
                    presentation == VAttachmentPresentation.modalBottomSheet,
                onSelected: () => onPresentationChanged(
                  VAttachmentPresentation.modalBottomSheet,
                ),
              ),
              _choice(
                label: 'Inline tray',
                selected: presentation == VAttachmentPresentation.inlineTray,
                onSelected: () =>
                    onPresentationChanged(VAttachmentPresentation.inlineTray),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ControlGroup(
            label: 'Launcher',
            children: [
              _choice(
                label: 'Inside input',
                selected:
                    launcherPlacement ==
                    VAttachmentLauncherPlacement.insideInput,
                onSelected: () => onLauncherPlacementChanged(
                  VAttachmentLauncherPlacement.insideInput,
                ),
              ),
              _choice(
                label: 'Leading outside',
                selected:
                    launcherPlacement ==
                    VAttachmentLauncherPlacement.leadingOutside,
                onSelected: () => onLauncherPlacementChanged(
                  VAttachmentLauncherPlacement.leadingOutside,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ControlGroup(
            label: 'Panel layout',
            children: [
              _choice(
                label: 'Grid',
                selected: panelLayout == VAttachmentPanelLayout.grid,
                onSelected: () =>
                    onPanelLayoutChanged(VAttachmentPanelLayout.grid),
              ),
              _choice(
                label: 'Horizontal',
                selected: panelLayout == VAttachmentPanelLayout.horizontalList,
                onSelected: () =>
                    onPanelLayoutChanged(VAttachmentPanelLayout.horizontalList),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        if (value) onSelected();
      },
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF18A779),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
    );
  }
}

class _FeatureBanner extends StatelessWidget {
  const _FeatureBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF128A66), Color(0xFF20B887)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24128A66),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A complete chat composer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Drop one widget into your conversation screen and connect its typed callbacks.',
            style: TextStyle(
              color: colors.surface.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureChip(icon: Icons.text_fields_rounded, label: 'Text'),
              _FeatureChip(icon: Icons.mic_none_rounded, label: 'Voice'),
              _FeatureChip(icon: Icons.attach_file_rounded, label: 'Files'),
              _FeatureChip(
                icon: Icons.alternate_email_rounded,
                label: 'Mentions',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoMessage {
  const _DemoMessage({
    required this.text,
    required this.time,
    this.isMine = false,
    this.isVoice = false,
  });

  final String text;
  final String time;
  final bool isMine;
  final bool isVoice;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _DemoMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
        decoration: BoxDecoration(
          color: message.isMine
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isMine ? 18 : 4),
            bottomRight: Radius.circular(message.isMine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isVoice) ...[
                  Icon(Icons.play_circle_fill_rounded, color: colors.primary),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(message.text)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (message.isMine) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded, size: 14, color: colors.primary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

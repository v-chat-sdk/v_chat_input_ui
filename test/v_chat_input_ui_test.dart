// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_chat_input_ui/v_chat_input_ui.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  group('VInputLanguage', () {
    test('provides usable English and accessibility defaults', () {
      const language = VInputLanguage();

      expect(language.textFieldHint, 'Type your message...');
      expect(language.media, 'Media');
      expect(language.files, 'Files');
      expect(language.location, 'Location');
      expect(language.sendButtonLabel, 'Send message');
      expect(language.recordButtonLabel, 'Record voice message');
      expect(language.emojiPickerLabel, 'Emoji picker');
      expect(language.emojiSearchHint, 'Search emojis');
      expect(language.noRecentEmojisLabel, 'No recent emojis');
    });

    test('accepts consumer-provided labels', () {
      const language = VInputLanguage(
        textFieldHint: 'Write a message',
        media: 'Photos',
        files: 'Documents',
        sendButtonLabel: 'Send now',
        emojiSearchHint: 'Find emoji',
      );

      expect(language.textFieldHint, 'Write a message');
      expect(language.media, 'Photos');
      expect(language.files, 'Documents');
      expect(language.sendButtonLabel, 'Send now');
      expect(language.emojiSearchHint, 'Find emoji');
    });
  });

  test('public attachment and typing states remain exported', () {
    expect(AttachEnumRes.values, [
      AttachEnumRes.media,
      AttachEnumRes.files,
      AttachEnumRes.location,
    ]);
    expect(RoomTypingEnum.values, [
      RoomTypingEnum.stop,
      RoomTypingEnum.typing,
      RoomTypingEnum.recording,
    ]);
  });

  testWidgets('uses the VInputTheme registered on ThemeData', (tester) async {
    final configuredTheme = VInputTheme.light(
      containerDecoration: const BoxDecoration(color: Colors.orange),
    );
    late VInputTheme resolvedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [configuredTheme]),
        home: Builder(
          builder: (context) {
            resolvedTheme = context.vInputTheme;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolvedTheme, same(configuredTheme));
  });

  test('interpolates animatable theme values', () {
    final start = VInputTheme.light(
      containerDecoration: const BoxDecoration(color: Colors.red),
      textFieldTextStyle: const TextStyle(fontSize: 12),
      composerActionExtent: 40,
    );
    final end = VInputTheme.light(
      containerDecoration: const BoxDecoration(color: Colors.blue),
      textFieldTextStyle: const TextStyle(fontSize: 20),
      composerActionExtent: 56,
    );

    final midpoint = start.lerp(end, 0.5) as VInputTheme;
    expect(
      midpoint.containerDecoration.color,
      Color.lerp(Colors.red, Colors.blue, 0.5),
    );
    expect(midpoint.textFieldTextStyle.fontSize, 16);
    expect(midpoint.composerActionExtent, 48);
    expect(
      midpoint.emojiPickerTheme.backgroundColor,
      Color.lerp(
        start.emojiPickerTheme.backgroundColor,
        end.emojiPickerTheme.backgroundColor,
        0.5,
      ),
    );
  });

  testWidgets('submits text and reports typing transitions', (tester) async {
    String? submittedMessage;
    final typingStates = <RoomTypingEnum>[];

    await tester.pumpWidget(
      _ComposerHost(
        onSubmitText: (message) => submittedMessage = message,
        onTypingChange: typingStates.add,
      ),
    );

    await tester.enterText(find.byType(CupertinoTextField), 'Hello package');
    await tester.pump();
    expect(typingStates, contains(RoomTypingEnum.typing));

    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(submittedMessage, 'Hello package');
    expect(typingStates.last, RoomTypingEnum.stop);
    expect(find.text('Hello package'), findsNothing);
  });

  testWidgets('can keep a long hint on one line without limiting input', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const hint = 'Write a longer message that does not fit on one line';
    await tester.pumpWidget(
      const _ComposerHost(
        language: VInputLanguage(textFieldHint: hint),
        singleLineHint: true,
      ),
    );

    final field = tester.widget<CupertinoTextField>(
      find.byType(CupertinoTextField),
    );
    expect(field.maxLines, 5);
    expect(field.placeholder, isNull);
    final visibleHint = tester.widget<Text>(find.text(hint));
    expect(visibleHint.maxLines, 1);
    expect(visibleHint.overflow, TextOverflow.ellipsis);
    expect(
      tester.renderObject<RenderParagraph>(find.text(hint)).didExceedMaxLines,
      isTrue,
    );

    await tester.tapAt(tester.getCenter(find.text(hint)));
    await tester.pump();
    expect(field.focusNode!.hasFocus, isTrue);

    await tester.enterText(find.byType(CupertinoTextField), 'one\ntwo');
    await tester.pump();
    expect(find.text(hint), findsNothing);
    expect(
      tester
          .widget<CupertinoTextField>(find.byType(CupertinoTextField))
          .maxLines,
      5,
    );

    await tester.enterText(find.byType(CupertinoTextField), '');
    await tester.pump();
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('keeps the built-in placeholder by default', (tester) async {
    await tester.pumpWidget(const _ComposerHost());
    expect(
      tester
          .widget<CupertinoTextField>(find.byType(CupertinoTextField))
          .placeholder,
      'Type your message...',
    );
  });

  testWidgets('can hide optional composer actions', (tester) async {
    await tester.pumpWidget(
      const _ComposerHost(
        enableEmojiPicker: false,
        enableAttachments: false,
        enableCamera: false,
        enableVoiceRecording: false,
      ),
    );

    expect(find.byTooltip('Open emoji picker'), findsNothing);
    expect(find.byTooltip('Add attachment'), findsNothing);
    expect(find.byTooltip('Open camera'), findsNothing);
    expect(find.byTooltip('Record voice message'), findsNothing);
  });

  testWidgets('drops oversized files before submission', (tester) async {
    final originalPlatform = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _FakeFilePickerPlatform([
      _MemoryPlatformFile('small.txt', Uint8List(4)),
      _MemoryPlatformFile('large.txt', Uint8List(12)),
    ]);
    addTearDown(() => FilePickerPlatform.instance = originalPlatform);
    List<VPlatformFile>? submittedFiles;

    await tester.pumpWidget(
      _ComposerHost(
        maxMediaSize: 5,
        onAttachIconPress: () async => AttachEnumRes.files,
        onSubmitFiles: (files) => submittedFiles = files,
      ),
    );

    await tester.tap(find.byTooltip('Add attachment'));
    await tester.pumpAndSettle();

    expect(submittedFiles, hasLength(1));
    expect(submittedFiles!.single.name, 'small.txt');
    expect(
      find.text('One or more files exceed the allowed size'),
      findsOneWidget,
    );
  });
}

class _ComposerHost extends StatelessWidget {
  const _ComposerHost({
    this.onSubmitText,
    this.onSubmitFiles,
    this.onTypingChange,
    this.onAttachIconPress,
    this.maxMediaSize = 50 * 1024 * 1024,
    this.enableEmojiPicker = true,
    this.enableAttachments = true,
    this.enableCamera = true,
    this.enableVoiceRecording = true,
    this.language = const VInputLanguage(),
    this.singleLineHint = false,
  });

  final ValueChanged<String>? onSubmitText;
  final ValueChanged<List<VPlatformFile>>? onSubmitFiles;
  final ValueChanged<RoomTypingEnum>? onTypingChange;
  final Future<AttachEnumRes?> Function()? onAttachIconPress;
  final int maxMediaSize;
  final bool enableEmojiPicker;
  final bool enableAttachments;
  final bool enableCamera;
  final bool enableVoiceRecording;
  final VInputLanguage language;
  final bool singleLineHint;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: VMessageInputWidget(
          maxMediaSize: maxMediaSize,
          onAttachIconPress: onAttachIconPress,
          enableEmojiPicker: enableEmojiPicker,
          enableAttachments: enableAttachments,
          enableCamera: enableCamera,
          enableVoiceRecording: enableVoiceRecording,
          language: language,
          singleLineHint: singleLineHint,
          onSubmitText: onSubmitText ?? (_) {},
          onSubmitMedia: (_) {},
          onSubmitFiles: onSubmitFiles ?? (_) {},
          onSubmitLocation: (_) {},
          onSubmitVoice: (_) {},
          onTypingChange: onTypingChange ?? (_) {},
        ),
      ),
    );
  }
}

class _FakeFilePickerPlatform extends FilePickerPlatform {
  _FakeFilePickerPlatform(this.files);

  final List<PlatformFile> files;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    Object? darwinOptions,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return files;
  }
}

base class _MemoryPlatformFile extends PlatformFile {
  _MemoryPlatformFile(this.name, this.data);

  @override
  final String name;
  final Uint8List data;

  @override
  Uri get uri => Uri.parse('memory:$name');

  @override
  XFile get xFile => XFile.fromData(data, name: name);

  @override
  Future<int> length() async => data.length;

  // ignore: annotate_overrides
  int? lengthSync() => data.length;

  @override
  Future<Uint8List> readAsBytes() async => data;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(data);
}

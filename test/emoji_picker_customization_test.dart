// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_chat_input_ui/v_chat_input_ui.dart';

void main() {
  test('emoji picker theme copies and interpolates visual values', () {
    const light = VEmojiPickerThemeData.light(
      backgroundColor: Colors.white,
      accentColor: Colors.green,
      height: 240,
      columns: 7,
      emojiSizeMax: 26,
    );
    const dark = VEmojiPickerThemeData.dark(
      backgroundColor: Colors.black,
      accentColor: Colors.blue,
      height: 320,
      columns: 10,
      emojiSizeMax: 30,
    );

    final copy = light.copyWith(accentColor: Colors.orange);
    final midpoint = light.lerp(dark, 0.5);

    expect(copy.backgroundColor, Colors.white);
    expect(copy.accentColor, Colors.orange);
    expect(
      midpoint.backgroundColor,
      Color.lerp(Colors.white, Colors.black, 0.5),
    );
    expect(midpoint.height, 280);
    expect(midpoint.columns, 10);
    expect(midpoint.emojiSizeMax, 28);
  });

  testWidgets('built-in picker follows live theme changes', (tester) async {
    final controller = VMessageInputController();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    await tester.pumpWidget(
      _EmojiHost(controller: controller, brightness: Brightness.light),
    );
    await tester.enterText(find.byType(CupertinoTextField), 'draft');
    controller.showEmoji();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    var picker = tester.widget<EmojiPicker>(find.byType(EmojiPicker));
    expect(picker.config.height, isNull);
    expect(
      picker.config.emojiViewConfig.backgroundColor,
      const VEmojiPickerThemeData.light().backgroundColor,
    );
    expect(picker.config.categoryViewConfig.initCategory, Category.SMILEYS);
    expect(
      picker.config.categoryViewConfig.recentTabBehavior,
      RecentTabBehavior.RECENT,
    );
    expect(picker.config.skinToneConfig.rememberSkinTone, isTrue);
    expect(picker.config.searchViewConfig.hintText, 'Find an emoji');

    await tester.pumpWidget(
      _EmojiHost(controller: controller, brightness: Brightness.dark),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    picker = tester.widget<EmojiPicker>(find.byType(EmojiPicker));
    const darkTheme = VEmojiPickerThemeData.dark();
    expect(
      picker.config.emojiViewConfig.backgroundColor,
      darkTheme.backgroundColor,
    );
    expect(
      picker.config.categoryViewConfig.backgroundColor,
      darkTheme.barColor,
    );
    expect(
      picker.config.bottomActionBarConfig.buttonIconColor,
      darkTheme.accentColor,
    );
    expect(find.text('draft'), findsOneWidget);

    controller.showKeyboard();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoTextField>(find.byType(CupertinoTextField))
          .controller!
          .text,
      'draft',
    );
  });

  testWidgets('responsive picker derives columns from available width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = VMessageInputController();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    await tester.pumpWidget(_EmojiHost(controller: controller));
    controller.showEmoji();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    var picker = tester.widget<EmojiPicker>(find.byType(EmojiPicker));
    expect(picker.config.emojiViewConfig.columns, inInclusiveRange(6, 8));

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pump();
    picker = tester.widget<EmojiPicker>(find.byType(EmojiPicker));
    expect(picker.config.emojiViewConfig.columns, 12);
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('custom emoji builder receives the active text controller', (
    tester,
  ) async {
    final controller = VMessageInputController();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    await tester.pumpWidget(
      _EmojiHost(
        controller: controller,
        emojiPickerBuilder: (context, textController) => Center(
          child: Text(
            'Custom picker: ${textController.text}',
            key: const ValueKey('custom-emoji-picker'),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(CupertinoTextField), 'hello');
    controller.showEmoji();
    await tester.pump();

    expect(find.byKey(const ValueKey('custom-emoji-picker')), findsOneWidget);
    expect(find.text('Custom picker: hello'), findsOneWidget);
    expect(find.byType(EmojiPicker), findsNothing);
  });
}

class _EmojiHost extends StatelessWidget {
  const _EmojiHost({
    required this.controller,
    this.brightness = Brightness.light,
    this.emojiPickerBuilder,
  });

  final VMessageInputController controller;
  final Brightness brightness;
  final VEmojiPickerBuilder? emojiPickerBuilder;

  @override
  Widget build(BuildContext context) {
    final inputTheme = brightness == Brightness.dark
        ? VInputTheme.dark()
        : VInputTheme.light();
    return MaterialApp(
      theme: ThemeData(brightness: brightness, extensions: [inputTheme]),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: VMessageInputWidget(
            controller: controller,
            language: const VInputLanguage(emojiSearchHint: 'Find an emoji'),
            emojiPickerBuilder: emojiPickerBuilder,
            enableAttachments: false,
            enableCamera: false,
            enableVoiceRecording: false,
            onSubmitText: (_) {},
            onSubmitMedia: (_) {},
            onSubmitVoice: (_) {},
            onSubmitFiles: (_) {},
            onSubmitLocation: (_) {},
            onTypingChange: (_) {},
          ),
        ),
      ),
    );
  }
}

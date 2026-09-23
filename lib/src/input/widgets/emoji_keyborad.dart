// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:v_platform/v_platform.dart';

import '../../models/models.dart';

class EmojiKeyboard extends StatelessWidget {
  final bool isEmojiShowing;
  final TextEditingController controller;
  final VInputLanguage language;
  final VEmojiPickerBuilder? builder;

  const EmojiKeyboard({
    super.key,
    required this.isEmojiShowing,
    required this.controller,
    required this.language,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEmojiShowing) {
      return const SizedBox.shrink();
    }
    final pickerTheme = context.vInputTheme.emojiPickerTheme;
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final maximumHeight =
        VPlatforms.isWeb ||
            VPlatforms.isWindows ||
            VPlatforms.isLinux ||
            VPlatforms.isMacOs
        ? 360.0
        : 320.0;
    final pickerHeight =
        pickerTheme.height ??
        (mediaHeight / 3).clamp(220.0, maximumHeight).toDouble();

    return Semantics(
      container: true,
      label: language.emojiPickerLabel,
      child: SizedBox(
        key: const ValueKey('v_emoji_picker_panel'),
        height: pickerHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (builder != null) {
              return builder!(context, controller);
            }

            final responsiveColumns = (constraints.maxWidth / 44)
                .floor()
                .clamp(6, 12)
                .toInt();
            final columns = pickerTheme.columns ?? responsiveColumns;
            final platform = Theme.of(context).platform;

            return EmojiPicker(
              textEditingController: controller,
              config: Config(
                height: null,
                locale:
                    Localizations.maybeLocaleOf(context) ?? const Locale('en'),
                checkPlatformCompatibility: true,
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.categoryBar,
                  middle: EmojiPickerItem.emojiView,
                  bottom: EmojiPickerItem.searchBar,
                ),
                emojiViewConfig: EmojiViewConfig(
                  columns: columns,
                  emojiSizeMax: platform == TargetPlatform.iOS
                      ? pickerTheme.emojiSizeMax * 1.2
                      : pickerTheme.emojiSizeMax,
                  backgroundColor: pickerTheme.backgroundColor,
                  gridPadding: pickerTheme.gridPadding,
                  recentsLimit: 28,
                  replaceEmojiOnLimitExceed: true,
                  noRecents: Center(
                    child: Text(
                      language.noRecentEmojisLabel,
                      style: pickerTheme.secondaryTextStyle.copyWith(
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  loadingIndicator: Center(
                    child: CircularProgressIndicator(
                      color: pickerTheme.accentColor,
                    ),
                  ),
                  buttonMode: platform == TargetPlatform.iOS
                      ? ButtonMode.CUPERTINO
                      : ButtonMode.MATERIAL,
                ),
                skinToneConfig: SkinToneConfig(
                  dialogBackgroundColor: pickerTheme.barColor,
                  indicatorColor: pickerTheme.accentColor,
                  rememberSkinTone: true,
                ),
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.SMILEYS,
                  recentTabBehavior: RecentTabBehavior.RECENT,
                  backgroundColor: pickerTheme.barColor,
                  indicatorColor: pickerTheme.accentColor,
                  iconColor: pickerTheme.iconColor,
                  iconColorSelected: pickerTheme.accentColor,
                  backspaceColor: pickerTheme.accentColor,
                  dividerColor: pickerTheme.dividerColor,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: pickerTheme.barColor,
                  buttonColor: pickerTheme.barColor,
                  buttonIconColor: pickerTheme.accentColor,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: pickerTheme.backgroundColor,
                  buttonIconColor: pickerTheme.accentColor,
                  inputTextStyle: pickerTheme.textStyle,
                  hintText: language.emojiSearchHint,
                  hintTextStyle: pickerTheme.secondaryTextStyle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

/// Replaces the built-in emoji picker while preserving composer behavior.
typedef VEmojiPickerBuilder =
    Widget Function(BuildContext context, TextEditingController controller);

/// Visual and responsive configuration for the built-in emoji picker.
@immutable
class VEmojiPickerThemeData {
  const VEmojiPickerThemeData.light({
    this.backgroundColor = const Color(0xFFF7F9F8),
    this.barColor = Colors.white,
    this.accentColor = const Color(0xFF168A63),
    this.iconColor = const Color(0xFF66736F),
    this.dividerColor = const Color(0xFFDDE5E2),
    this.textStyle = const TextStyle(color: Color(0xFF1D2925)),
    this.secondaryTextStyle = const TextStyle(color: Color(0xFF6F7D78)),
    this.gridPadding = const EdgeInsets.symmetric(vertical: 8),
    this.height,
    this.columns,
    this.emojiSizeMax = 28,
  }) : assert(height == null || height > 0),
       assert(columns == null || columns > 0),
       assert(emojiSizeMax > 0);

  const VEmojiPickerThemeData.dark({
    this.backgroundColor = const Color(0xFF111816),
    this.barColor = const Color(0xFF202A27),
    this.accentColor = const Color(0xFF5EE0B6),
    this.iconColor = const Color(0xFFA9B8B3),
    this.dividerColor = const Color(0xFF33433E),
    this.textStyle = const TextStyle(color: Colors.white),
    this.secondaryTextStyle = const TextStyle(color: Color(0xFFA9B8B3)),
    this.gridPadding = const EdgeInsets.symmetric(vertical: 8),
    this.height,
    this.columns,
    this.emojiSizeMax = 28,
  }) : assert(height == null || height > 0),
       assert(columns == null || columns > 0),
       assert(emojiSizeMax > 0);

  const VEmojiPickerThemeData._({
    required this.backgroundColor,
    required this.barColor,
    required this.accentColor,
    required this.iconColor,
    required this.dividerColor,
    required this.textStyle,
    required this.secondaryTextStyle,
    required this.gridPadding,
    required this.height,
    required this.columns,
    required this.emojiSizeMax,
  });

  /// Background behind the emoji grid and search view.
  final Color backgroundColor;

  /// Background of the category and bottom action bars.
  final Color barColor;

  /// Selected category, search, backspace, and progress-indicator color.
  final Color accentColor;

  /// Unselected category icon color.
  final Color iconColor;

  /// Divider color between picker sections.
  final Color dividerColor;

  /// Text style used by the search field.
  final TextStyle textStyle;

  /// Text style used by hints and empty states.
  final TextStyle secondaryTextStyle;

  /// Padding around the emoji grid.
  final EdgeInsets gridPadding;

  /// Fixed picker height, or `null` to derive it from the viewport.
  final double? height;

  /// Fixed emoji column count, or `null` to derive it from available width.
  final int? columns;

  /// Maximum rendered emoji size before the iOS compatibility multiplier.
  final double emojiSizeMax;

  VEmojiPickerThemeData copyWith({
    Color? backgroundColor,
    Color? barColor,
    Color? accentColor,
    Color? iconColor,
    Color? dividerColor,
    TextStyle? textStyle,
    TextStyle? secondaryTextStyle,
    EdgeInsets? gridPadding,
    double? height,
    int? columns,
    double? emojiSizeMax,
  }) {
    return VEmojiPickerThemeData._(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      barColor: barColor ?? this.barColor,
      accentColor: accentColor ?? this.accentColor,
      iconColor: iconColor ?? this.iconColor,
      dividerColor: dividerColor ?? this.dividerColor,
      textStyle: textStyle ?? this.textStyle,
      secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
      gridPadding: gridPadding ?? this.gridPadding,
      height: height ?? this.height,
      columns: columns ?? this.columns,
      emojiSizeMax: emojiSizeMax ?? this.emojiSizeMax,
    );
  }

  VEmojiPickerThemeData lerp(VEmojiPickerThemeData other, double t) {
    return VEmojiPickerThemeData._(
      backgroundColor:
          Color.lerp(backgroundColor, other.backgroundColor, t) ??
          backgroundColor,
      barColor: Color.lerp(barColor, other.barColor, t) ?? barColor,
      accentColor: Color.lerp(accentColor, other.accentColor, t) ?? accentColor,
      iconColor: Color.lerp(iconColor, other.iconColor, t) ?? iconColor,
      dividerColor:
          Color.lerp(dividerColor, other.dividerColor, t) ?? dividerColor,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t) ?? textStyle,
      secondaryTextStyle:
          TextStyle.lerp(secondaryTextStyle, other.secondaryTextStyle, t) ??
          secondaryTextStyle,
      gridPadding:
          EdgeInsets.lerp(gridPadding, other.gridPadding, t) ?? gridPadding,
      height: _lerpNullableDouble(height, other.height, t),
      columns: t < 0.5 ? columns : other.columns,
      emojiSizeMax: emojiSizeMax + (other.emojiSizeMax - emojiSizeMax) * t,
    );
  }

  static double? _lerpNullableDouble(double? start, double? end, double t) {
    if (start == null || end == null) {
      return t < 0.5 ? start : end;
    }
    return start + (end - start) * t;
  }
}

// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';

extension MediaQueryExt2 on BuildContext {
  bool get isDark => CupertinoTheme.of(this).brightness == Brightness.dark;
  CupertinoTextThemeData get cupertinoTextTheme =>
      CupertinoTheme.of(this).textTheme;
  Future<T?> toPage<T>(Widget page) =>
      Navigator.push(this, CupertinoPageRoute(builder: (context) => page));

  bool get isRtl => Directionality.of(this).name.toLowerCase() == "rtl";
}

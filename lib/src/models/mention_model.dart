// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:v_platform/v_platform.dart';

class MentionModel {
  final String peerId;
  final String name;
  final String image;

  const MentionModel({
    required this.peerId,
    required this.name,
    required this.image,
  });

  String get imageS3 =>
      VPlatformFile.fromUrl(networkUrl: image).fullNetworkUrl!;

  Map<String, dynamic> toMap() {
    return {'peerId': peerId, 'name': name, 'image': image};
  }

  factory MentionModel.fromMap(Map<String, dynamic> map) {
    return MentionModel(
      peerId: map['peerId'] as String,
      name: map['name'] as String,
      image: map['image'] as String,
    );
  }
}

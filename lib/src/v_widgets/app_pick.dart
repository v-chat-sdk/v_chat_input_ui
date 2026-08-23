// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:v_platform/v_platform.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

abstract class VAppPick {
  static bool isPicking = false;

  static Future<T> _whilePicking<T>(Future<T> Function() action) async {
    isPicking = true;
    try {
      return await action();
    } finally {
      isPicking = false;
    }
  }

  static Future<VPlatformFile?> getCroppedImage({
    bool isFromCamera = false,
  }) async {
    final img = await getImage(isFromCamera: isFromCamera);
    if (img != null) {
      if (VPlatforms.isMobile) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: img.fileLocalPath!,
          compressQuality: 70,
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop It',
              toolbarColor: Colors.white,
              toolbarWidgetColor: Colors.black,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Crop It'),
          ],
        );

        if (croppedFile == null) {
          return null;
        }
        return VPlatformFile.fromPath(fileLocalPath: croppedFile.path);
      }
      return img;
    }
    return null;
  }

  static Future<VPlatformFile?> getImage({bool isFromCamera = false}) async {
    final pickedFile = await _whilePicking(
      () => FilePicker.pickFile(type: FileType.image),
    );
    if (pickedFile == null) return null;
    return _toVPlatformFile(pickedFile);
  }

  static Future<List<VPlatformFile>?> getImages() async {
    final pickedFiles = await _whilePicking(
      () => FilePicker.pickFiles(type: FileType.image),
    );
    if (pickedFiles.isEmpty) return null;
    return Future.wait(pickedFiles.map(_toVPlatformFile));
  }

  static Future<({List<VPlatformFile> files, int oversizedCount})?> getMedia({
    int? maxFileSize,
  }) async {
    final pickedFiles = await _whilePicking(
      () => FilePicker.pickFiles(type: FileType.media),
    );
    return _convertPickedFiles(pickedFiles, maxFileSize: maxFileSize);
  }

  static Future<VPlatformFile?> getVideo() async {
    final pickedFile = await _whilePicking(
      () => FilePicker.pickFile(type: FileType.video),
    );
    if (pickedFile == null) return null;
    return _toVPlatformFile(pickedFile);
  }

  static Future<({List<VPlatformFile> files, int oversizedCount})?> getFiles({
    int? maxFileSize,
  }) async {
    final pickedFiles = await _whilePicking(FilePicker.pickFiles);
    return _convertPickedFiles(pickedFiles, maxFileSize: maxFileSize);
  }

  static Future<({List<VPlatformFile> files, int oversizedCount})?>
  _convertPickedFiles(
    List<PlatformFile> pickedFiles, {
    int? maxFileSize,
  }) async {
    if (pickedFiles.isEmpty) return null;
    final acceptedFiles = <PlatformFile>[];
    var oversizedCount = 0;
    for (final file in pickedFiles) {
      if (maxFileSize != null && await file.length() > maxFileSize) {
        oversizedCount++;
      } else {
        acceptedFiles.add(file);
      }
    }
    return (
      files: await Future.wait(acceptedFiles.map(_toVPlatformFile)),
      oversizedCount: oversizedCount,
    );
  }

  static Future<VPlatformFile> _toVPlatformFile(PlatformFile file) async {
    if (file.path != null) {
      return VPlatformFile.fromPath(fileLocalPath: file.path!);
    }
    return VPlatformFile.fromBytes(
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }

  static Future<VPlatformFile?> pickFromWeAssetCamera({
    XFileCapturedCallback? onXFileCaptured,
    required BuildContext context,
    int videoSeconds = 45,
  }) async {
    final AssetEntity? entity = await CameraPicker.pickFromCamera(
      context,
      pickerConfig: CameraPickerConfig(
        enableRecording: true,
        enableTapRecording: true,
        maximumRecordingDuration: Duration(seconds: videoSeconds),
        textDelegate: const EnglishCameraPickerTextDelegate(),
        onXFileCaptured: onXFileCaptured,
        shouldAutoPreviewVideo: true,
      ),
    );
    if (entity == null) {
      return null;
    }
    final f = (await entity.file)!;
    return VPlatformFile.fromPath(fileLocalPath: f.path);
  }

  static Future<void> clearPickerCache() async {
    await FilePicker.clearTemporaryFiles();
  }

  static Future<VPlatformFile?> croppedImage({
    required VPlatformFile file,
    List<CropAspectRatioPreset>? aspectRatioPresets,
  }) async {
    if (!file.isContentImage) return null;
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: file.fileLocalPath!,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Cropper'),
      ],
    );
    if (croppedFile != null) {
      return VPlatformFile.fromPath(fileLocalPath: croppedFile.path);
    }
    return null;
  }
}

// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

class VInputLanguage {
  final String textFieldHint;
  final String media;
  final String camera;
  final String files;
  final String cancel;
  final String location;
  final String shareMediaAndLocation;
  final String thereIsVideoSizeBiggerThanAllowedSize;
  final String thereIsFileHasSizeBiggerThanAllowedSize;
  final String emojiButtonLabel;
  final String attachmentButtonLabel;
  final String openAttachmentsButtonLabel;
  final String cameraButtonLabel;
  final String sendButtonLabel;
  final String recordButtonLabel;
  final String cancelRecordingButtonLabel;
  final String attachmentPanelLabel;
  final String returnToKeyboardButtonLabel;
  final String closeAttachmentPanelButtonLabel;
  final String emojiPickerLabel;
  final String emojiSearchHint;
  final String noRecentEmojisLabel;

  const VInputLanguage({
    this.textFieldHint = "Type your message...",
    this.media = "Media",
    this.camera = "Camera",
    this.files = "Files",
    this.cancel = "Cancel",
    this.location = "Location",
    this.shareMediaAndLocation = "Share media and location",
    this.thereIsVideoSizeBiggerThanAllowedSize =
        "One or more media files exceed the allowed size",
    this.thereIsFileHasSizeBiggerThanAllowedSize =
        "One or more files exceed the allowed size",
    this.emojiButtonLabel = "Open emoji picker",
    this.attachmentButtonLabel = "Add attachment",
    String? openAttachmentsButtonLabel,
    this.cameraButtonLabel = "Open camera",
    this.sendButtonLabel = "Send message",
    this.recordButtonLabel = "Record voice message",
    this.cancelRecordingButtonLabel = "Cancel voice recording",
    this.attachmentPanelLabel = "Attachment actions",
    this.returnToKeyboardButtonLabel = "Show keyboard",
    this.closeAttachmentPanelButtonLabel = "Close attachment actions",
    this.emojiPickerLabel = "Emoji picker",
    this.emojiSearchHint = "Search emojis",
    this.noRecentEmojisLabel = "No recent emojis",
  }) : openAttachmentsButtonLabel =
           openAttachmentsButtonLabel ?? attachmentButtonLabel;
}

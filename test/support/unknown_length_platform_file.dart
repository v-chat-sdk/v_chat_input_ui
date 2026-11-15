import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

final class UnknownLengthPlatformFile extends PlatformFile {
  UnknownLengthPlatformFile(this.name, this.data);
  @override
  final String name;
  final Uint8List data;
  int byteReads = 0;
  int streamedBytes = 0;
  @override
  Uri get uri => Uri.parse('memory:$name');
  @override
  XFile get xFile => XFile.fromData(data, name: name);
  @override
  Future<int?> length() async => null;
  @override
  int? lengthSync() => null;
  @override
  Future<Uint8List> readAsBytes() async {
    byteReads++;
    return data;
  }

  @override
  Stream<Uint8List> readAsByteStream() async* {
    for (final byte in data) {
      streamedBytes++;
      yield Uint8List.fromList([byte]);
    }
  }
}

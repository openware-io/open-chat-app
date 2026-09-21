import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

import 'chat_backup_file_io.dart';

/// Web：触发浏览器下载；返回文件名作为「保存位置」提示（浏览器自动落盘到下载目录）。
Future<String?> saveChatBackupFile(
  String fileName,
  Uint8List bytes, {
  String? dialogTitle,
}) async {
  final parts = <web.BlobPart>[bytes.toJS].toJS;
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  try {
    web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..click();
  } finally {
    web.URL.revokeObjectURL(url);
  }
  return fileName;
}

Future<PickedBackupFile?> pickChatBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final picked = result.files.single;
  final bytes = picked.bytes;
  if (bytes == null || bytes.isEmpty) return null;
  return PickedBackupFile(name: picked.name, bytes: bytes);
}

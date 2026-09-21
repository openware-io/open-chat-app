import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'chat_backup_file_io.dart';

/// 原生平台：优先用系统「另存为」对话框写入用户选择的位置；
/// 平台不支持（如 iOS）或用户取消时回退到应用文档目录并返回路径。
Future<String?> saveChatBackupFile(
  String fileName,
  Uint8List bytes, {
  String? dialogTitle,
}) async {
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (path != null && path.isNotEmpty) {
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    }
    // 用户主动取消保存。
    return null;
  } on UnsupportedError {
    // 平台不支持 saveFile：回退到应用文档目录。
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<PickedBackupFile?> pickChatBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    allowMultiple: false,
    withData: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final picked = result.files.single;
  final path = picked.path;
  if (path == null || path.isEmpty) return null;
  final bytes = await File(path).readAsBytes();
  return PickedBackupFile(name: picked.name, bytes: bytes);
}

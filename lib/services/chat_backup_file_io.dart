import 'dart:typed_data';

export 'chat_backup_file_io_io.dart'
    if (dart.library.js_interop) 'chat_backup_file_io_web.dart';

/// 从用户选择的备份文件中读取到的内容。
class PickedBackupFile {
  const PickedBackupFile({required this.name, required this.bytes});

  /// 用户看到的文件名（含扩展名）。
  final String name;

  /// 文件内容。
  final Uint8List bytes;
}

import 'dart:io';

import 'package:flutter_hbb/common/file_transfer_logic.dart';

/// Reads a local OS path into a staged item. Does not start a transfer.
StagedLocalItem stageLocalPath(String path) {
  final entityType = FileSystemEntity.typeSync(path);
  final isDirectory = entityType == FileSystemEntityType.directory;
  var size = 0;
  if (entityType == FileSystemEntityType.file) {
    try {
      size = File(path).lengthSync();
    } catch (_) {
      size = 0;
    }
  }
  return stagedLocalItem(
    path: path,
    name: localBaseName(path),
    isDirectory: isDirectory,
    size: size,
  );
}

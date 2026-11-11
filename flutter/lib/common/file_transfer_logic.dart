import 'package:path/path.dart' as path;

/// Case-insensitive filename match for the current directory only.
List<T> filterEntriesByName<T>(
  Iterable<T> entries,
  String query,
  String Function(T entry) name,
) {
  final needle = query.toLowerCase();
  if (needle.isEmpty) {
    return List<T>.from(entries, growable: false);
  }
  return entries
      .where((entry) => name(entry).toLowerCase().contains(needle))
      .toList(growable: false);
}

/// Inclusive range inside [visible]. Indexes outside the list are clipped.
List<T> rangeBetween<T>(List<T> visible, int minIndex, int maxIndex) {
  if (visible.isEmpty || minIndex > maxIndex) {
    return <T>[];
  }
  final start = minIndex < 0 ? 0 : minIndex;
  final end = maxIndex >= visible.length ? visible.length - 1 : maxIndex;
  if (start > end) {
    return <T>[];
  }
  return visible.sublist(start, end + 1);
}

int indexByPath<T>(
  List<T> visible,
  String itemPath,
  int entryType,
  String Function(T entry) pathOf,
  int Function(T entry) typeOf,
) {
  for (var i = 0; i < visible.length; i++) {
    final entry = visible[i];
    if (pathOf(entry) == itemPath && typeOf(entry) == entryType) {
      return i;
    }
  }
  return -1;
}

/// Keeps the current directory objects that still match the previous selection.
/// Items absent from [current] are dropped, so a pending OS queue must not be
/// passed in here.
List<T> reconcileByPath<T>(
  List<T> selected,
  List<T> current,
  String Function(T entry) pathOf,
  int Function(T entry) typeOf,
) {
  final currentByKey = <String, T>{};
  for (final entry in current) {
    currentByKey['${typeOf(entry)}\u0000${pathOf(entry)}'] = entry;
  }
  final kept = <T>[];
  for (final item in selected) {
    final found = currentByKey['${typeOf(item)}\u0000${pathOf(item)}'];
    if (found != null) {
      kept.add(found);
    }
  }
  return kept;
}

bool canSendTransfer({
  required int directoryCount,
  required int pendingCount,
}) {
  return directoryCount > 0 || pendingCount > 0;
}

/// FileType::Dir = 0, FileType::File = 4. A bare Entry defaults to 4 (file).
int localEntryType({required bool isDirectory}) => isDirectory ? 0 : 4;

class StagedLocalItem {
  final String path;
  final String name;
  final bool isDirectory;
  final int size;

  const StagedLocalItem({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
  });

  int get entryType => localEntryType(isDirectory: isDirectory);
}

StagedLocalItem stagedLocalItem({
  required String path,
  required String name,
  required bool isDirectory,
  required int size,
}) {
  return StagedLocalItem(
    path: path,
    name: name,
    isDirectory: isDirectory,
    size: size,
  );
}

String localBaseName(String path) {
  var trimmed = path;
  while (
      trimmed.length > 1 && (trimmed.endsWith('/') || trimmed.endsWith('\\'))) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  final slash = trimmed.lastIndexOf('/');
  final back = trimmed.lastIndexOf('\\');
  final cut = slash > back ? slash : back;
  if (cut < 0 || cut + 1 >= trimmed.length) {
    return trimmed;
  }
  return trimmed.substring(cut + 1);
}

/// Join onto the target directory using the target machine's separator.
String joinTargetPath(
  String directory,
  String name, {
  required bool targetIsWindows,
}) {
  final ctx = targetIsWindows ? path.windows : path.posix;
  return ctx.join(directory, name);
}

void pushDirectoryHistory(List<String> history, String currentPath) {
  if (history.isNotEmpty && history.last == currentPath) {
    return;
  }
  history.add(currentPath);
}

class DirectoryOpenOutcome {
  final bool applied;
  final bool recordHistory;
  final bool stale;

  const DirectoryOpenOutcome({
    required this.applied,
    required this.recordHistory,
    required this.stale,
  });
}

/// A superseded response is ignored. A failed response does not record history.
DirectoryOpenOutcome directoryOpenOutcome({
  required int requestGeneration,
  required int latestGeneration,
  required bool isBack,
  required bool failed,
}) {
  if (requestGeneration != latestGeneration) {
    return const DirectoryOpenOutcome(
      applied: false,
      recordHistory: false,
      stale: true,
    );
  }
  if (failed) {
    return const DirectoryOpenOutcome(
      applied: false,
      recordHistory: false,
      stale: false,
    );
  }
  return DirectoryOpenOutcome(
    applied: true,
    recordHistory: !isBack,
    stale: false,
  );
}

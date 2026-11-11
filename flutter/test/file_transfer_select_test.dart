import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/file_transfer_logic.dart';
import 'package:flutter_hbb/desktop/local_file_stage.dart';
import 'package:flutter_hbb/desktop/widgets/file_transfer_bars.dart';
import 'package:flutter_test/flutter_test.dart';

class _Item {
  final String path;
  final int type;
  final String name;
  _Item(this.path, this.type, this.name);
}

void main() {
  test('filename filter is case-insensitive and stays in the current list', () {
    final names = ['Readme.txt', 'photo.PNG', 'notes.md'];
    final visible = filterEntriesByName(names, 'png', (name) => name);
    expect(visible, ['photo.PNG']);
    expect(filterEntriesByName(names, '', (name) => name), names);
  });

  test('select all after a filter keeps only visible names', () {
    final names = ['Readme.txt', 'photo.PNG', 'notes.md'];
    final selected = filterEntriesByName(names, 'png', (name) => name);
    expect(selected, ['photo.PNG']);
    expect(selected.contains('Readme.txt'), isFalse);
  });

  test('shift range stays inside the filtered list', () {
    final visible = ['a.txt', 'b.txt', 'c.txt'];
    expect(rangeBetween(visible, 0, 1), ['a.txt', 'b.txt']);
    expect(rangeBetween(visible, 0, 1).contains('hidden.txt'), isFalse);
  });

  test('reconcile returns the current object and drops names that left', () {
    final stale = _Item('/dir/a.txt', 4, 'a.txt');
    final current = _Item('/dir/a.txt', 4, 'a.txt');
    final pending = [_Item(r'C:\staged.txt', 4, 'staged.txt')];
    final kept = reconcileByPath(
      [stale, _Item('/dir/gone.txt', 4, 'gone.txt')],
      [current],
      (item) => item.path,
      (item) => item.type,
    );
    expect(kept, hasLength(1));
    expect(identical(kept.single, current), isTrue);
    expect(pending.single.name, 'staged.txt');
  });

  test('empty selection and empty pending cannot send', () {
    expect(
      canSendTransfer(directoryCount: 0, pendingCount: 0),
      isFalse,
    );
    expect(
      canSendTransfer(directoryCount: 0, pendingCount: 1),
      isTrue,
    );
  });

  test('only the latest directory response applies, and failure skips history',
      () {
    final history = <String>['/a'];
    final first = directoryOpenOutcome(
      requestGeneration: 1,
      latestGeneration: 2,
      isBack: false,
      failed: false,
    );
    expect(first.stale, isTrue);
    expect(first.applied, isFalse);
    expect(first.recordHistory, isFalse);

    final failed = directoryOpenOutcome(
      requestGeneration: 2,
      latestGeneration: 2,
      isBack: false,
      failed: true,
    );
    expect(failed.applied, isFalse);
    expect(failed.recordHistory, isFalse);
    if (failed.recordHistory) {
      pushDirectoryHistory(history, '/a');
    }
    expect(history, ['/a']);

    final applied = directoryOpenOutcome(
      requestGeneration: 2,
      latestGeneration: 2,
      isBack: false,
      failed: false,
    );
    expect(applied.applied, isTrue);
    if (applied.recordHistory) {
      pushDirectoryHistory(history, '/a');
    }
    expect(history, ['/a']);
    pushDirectoryHistory(history, '/b');
    expect(history, ['/a', '/b']);
  });

  test('windows file name joins a linux target with a slash', () {
    expect(
      joinTargetPath('/home/user', 'b.txt', targetIsWindows: false),
      '/home/user/b.txt',
    );
    expect(
      joinTargetPath(r'C:\dest', 'b.txt', targetIsWindows: true),
      r'C:\dest\b.txt',
    );
  });

  test('folder stage is a directory and a file stage is a file', () {
    final root = Directory.systemTemp.createTempSync('ft-stage');
    addTearDown(() => root.deleteSync(recursive: true));
    final folder = Directory('${root.path}/folder')..createSync();
    final file = File('${root.path}/note.txt')..writeAsStringSync('hi');
    final stagedDir = stageLocalPath(folder.path);
    final stagedFile = stageLocalPath(file.path);
    expect(stagedDir.isDirectory, isTrue);
    expect(stagedDir.entryType < 3, isTrue);
    expect(stagedFile.isDirectory, isFalse);
    expect(stagedFile.entryType > 3, isTrue);
    expect(stagedFile.size, 2);
  });

  testWidgets('search field keeps its controller across rebuilds',
      (tester) async {
    final controller = TextEditingController();
    var submits = 0;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          return Scaffold(
            body: Column(
              children: [
                FileNameSearchBar(
                  controller: controller,
                  hint: 'Search',
                  clearTooltip: 'Clear',
                  onChanged: (_) {},
                  onClear: () {},
                  onSubmitted: (_) => submits += 1,
                ),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('rebuild'),
                ),
              ],
            ),
          );
        },
      ),
    ));
    await tester.enterText(find.byType(TextField), 'Ab');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submits, 1);
    expect(controller.text, 'Ab');
    await tester.tap(find.text('rebuild'));
    await tester.pump();
    expect(controller.text, 'Ab');
    expect(controller.selection.extentOffset, 2);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('clearing directory selection does not clear pending or send',
      (tester) async {
    var directoryClears = 0;
    var pendingClears = 0;
    var sends = 0;
    var directory = '/remote/inbox';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TransferSelectionBar(
          directoryCount: 2,
          pendingCount: 1,
          directoryLabel: 'Selected 2 items',
          pendingLabel: 'Pending 1 items',
          targetLabel: 'Target $directory',
          clearDirectoryLabel: 'Clear directory',
          clearPendingLabel: 'Clear pending',
          onClearDirectory: () => directoryClears += 1,
          onClearPending: () => pendingClears += 1,
        ),
      ),
    ));
    expect(find.text('Target /remote/inbox'), findsOneWidget);
    await tester.tap(find.text('Clear directory'));
    await tester.pump();
    expect(directoryClears, 1);
    expect(pendingClears, 0);
    expect(sends, 0);
    expect(directory, '/remote/inbox');
    expect(
      canSendTransfer(directoryCount: 0, pendingCount: 1),
      isTrue,
    );
  });

  testWidgets('no matches hint is the empty search state', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FileSearchEmptyHint(message: 'No matches')),
    ));
    expect(find.text('No matches'), findsOneWidget);
  });
}

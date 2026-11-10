import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/widgets/login_prompt.dart';
import 'package:flutter_hbb/desktop/widgets/compact_home.dart';

const _fixtureTabs = [
  '最近访问过',
  '收藏',
  '已发现',
  '地址簿',
  '可访问的设备',
];

const _fixturePeers = [
  ('办公室电脑', '123 456 001', true),
  ('HOME-PC', '123 456 002', true),
  ('会议室', '123 456 003', false),
  ('仓库主机', '123 456 004', true),
  ('设计工作站', '123 456 005', false),
  ('前台', '123 456 006', true),
  ('备用机', '123 456 007', false),
  ('实验室', '123 456 008', true),
];

var _fontsLoaded = false;

Future<void> _loadFamily(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var added = false;
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader
        .addFont(Future.value(ByteData.sublistView(await file.readAsBytes())));
    added = true;
  }
  if (added) await loader.load();
}

Future<void> _loadFixtureFonts(WidgetTester tester) async {
  if (_fontsLoaded) return;
  await tester.runAsync(() async {
    await _loadFamily('FixtureSans', [
      '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
      '/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf',
    ]);
    await _loadFamily('MaterialIcons', [
      '/home/ubuntu/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
    await _loadFamily('FixtureCJK', [
      '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
    ]);
  });
  _fontsLoaded = true;
}

void main() {
  test('incoming password text hides the real value with the shared rules', () {
    const secret = 'fixture-secret';
    final hidden = CompactPasswordState.resolve(
      showOneTime: true,
      raw: secret,
      serviceStopped: false,
      revealed: false,
    );
    expect(incomingPasswordVisibleText(hidden, secret), '••••••');
    final blocked = CompactPasswordState.resolve(
      showOneTime: false,
      raw: '-',
      serviceStopped: true,
      revealed: true,
    );
    expect(incomingPasswordVisibleText(blocked, '-'), '-');
    expect(incomingPasswordVisibleText(blocked, secret), '');
  });

  test('one-time password actions follow the existing board', () {
    const secret = 'fixture-secret';
    final hidden = CompactPasswordState.resolve(
      showOneTime: true,
      raw: secret,
      serviceStopped: false,
      revealed: false,
    );
    expect(hidden.showActions, isTrue);
    expect(hidden.display, '••••••');
    expect(hidden.display.contains(secret), isFalse);
    expect(hidden.copyText, secret);

    final shown = CompactPasswordState.resolve(
      showOneTime: true,
      raw: secret,
      serviceStopped: false,
      revealed: true,
    );
    expect(shown.display, secret);
    expect(shown.copyText, secret);

    for (final raw in ['-', '']) {
      final state = CompactPasswordState.resolve(
        showOneTime: true,
        raw: raw,
        serviceStopped: false,
        revealed: true,
      );
      expect(state.showActions, isFalse, reason: raw);
    }
    expect(
      CompactPasswordState.resolve(
        showOneTime: false,
        raw: secret,
        serviceStopped: false,
        revealed: false,
      ).showActions,
      isFalse,
    );
    expect(
      CompactPasswordState.resolve(
        showOneTime: true,
        raw: secret,
        serviceStopped: true,
        revealed: true,
      ).showActions,
      isFalse,
    );
  });

  testWidgets(
      'password stays masked until the eye is used, copy is the raw value',
      (tester) async {
    const secret = 'fixture-secret';
    var revealed = false;
    String? copied;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          final password = CompactPasswordState.resolve(
            showOneTime: true,
            raw: secret,
            serviceStopped: false,
            revealed: revealed,
          );
          return Scaffold(
            body: CompactIdentityBar(
              idLabel: 'ID',
              idText: '123 456 789',
              copyIdTip: 'Copy',
              onCopyId: () {},
              passwordLabel: 'One-time Password',
              password: password,
              revealTip: 'Password',
              onToggleReveal: () => setState(() => revealed = !revealed),
              copyPasswordTip: 'Copy',
              onCopyPassword: () => copied = password.copyText,
              refreshTip: 'Refresh',
              onRefreshPassword: () {},
            ),
          );
        },
      ),
    ));

    expect(find.text(secret), findsNothing);
    expect(find.text('••••••'), findsOneWidget);
    expect(find.byKey(const Key('compact-password-reveal')), findsOneWidget);

    await tester.tap(find.byKey(const Key('compact-password-copy')));
    expect(copied, secret);

    await tester.tap(find.byKey(const Key('compact-password-reveal')));
    await tester.pump();
    expect(find.text(secret), findsOneWidget);
  });

  testWidgets('no one-time password means no reveal, copy, or refresh',
      (tester) async {
    final password = CompactPasswordState.resolve(
      showOneTime: false,
      raw: '-',
      serviceStopped: false,
      revealed: false,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CompactIdentityBar(
          idLabel: 'ID',
          idText: '123 456 789',
          copyIdTip: 'Copy',
          onCopyId: () {},
          passwordLabel: 'One-time Password',
          password: password,
          revealTip: 'Password',
          onToggleReveal: () {},
          copyPasswordTip: 'Copy',
          onCopyPassword: () {},
          refreshTip: 'Refresh',
          onRefreshPassword: () {},
          onEditPassword: () {},
          editTip: 'Change',
        ),
      ),
    ));

    expect(find.byKey(const Key('compact-password-reveal')), findsNothing);
    expect(find.byKey(const Key('compact-password-copy')), findsNothing);
    expect(find.byKey(const Key('compact-password-refresh')), findsNothing);
    expect(find.byKey(const Key('compact-password-edit')), findsOneWidget);
    expect(find.text('示例设备'), findsNothing);
    expect(find.textContaining('192.168.1.101'), findsNothing);
  });

  testWidgets('800x600 long list keeps the local bar on screen in both themes',
      (tester) async {
    await _pumpHome(tester, Brightness.dark, const Size(800, 600));
    await _expectBarSurvivesScroll(tester, const Size(800, 600));
    await _pumpHome(tester, Brightness.light, const Size(800, 600));
    await _expectBarSurvivesScroll(tester, const Size(800, 600));
    await _pumpHome(
      tester,
      Brightness.dark,
      const Size(800, 600),
      textScale: 1.4,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('product connect header, tabs, scope, login and selection bar',
      (tester) async {
    var connected = 0;
    var filed = 0;
    var loggedIn = 0;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: CompactHomeScope(
        child: Builder(
          builder: (context) {
            expect(CompactHomeScope.isActive(context), isTrue);
            return Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: Column(
                  children: [
                    CompactConnectHeader(
                      field: TextField(
                        decoration: compactIdFieldDecoration(
                          context,
                          hint: '输入对方 ID',
                        ),
                      ),
                      connectLabel: '连接',
                      onConnect: () => connected += 1,
                      fileLabel: '传输文件',
                      onFile: () => filed += 1,
                      more: const Text('更多'),
                    ),
                    SizedBox(
                      height: 36,
                      child: CompactTabTrack(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: const [
                            CompactTabLabel(
                              label:
                                  'Recently used devices with a very long translated name',
                              selected: true,
                            ),
                            CompactTabLabel(label: '收藏', selected: false),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: LoginPromptButton(
                        label: '登录',
                        onPressed: () => loggedIn += 1,
                      ),
                    ),
                    SelectionActionBar(
                      showBulkActions: true,
                      bulkActions: const [
                        Icon(Icons.delete),
                        Icon(Icons.star),
                        Text('加入地址簿'),
                      ],
                      trailing: const Text('3'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ));
    expect(find.text('输入对方 ID'), findsOneWidget);
    expect(find.byKey(const Key('compact-connect')), findsOneWidget);
    expect(find.byKey(const Key('compact-file')), findsOneWidget);
    expect(
      find.text('Recently used devices with a very long translated name'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('login-prompt')), findsOneWidget);
    expect(find.text('示例设备'), findsNothing);
    await tester.tap(find.byKey(const Key('compact-connect')));
    await tester.tap(find.byKey(const Key('compact-file')));
    await tester.tap(find.byKey(const Key('login-prompt')));
    expect(connected, 1);
    expect(filed, 1);
    expect(loggedIn, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(CompactHomeScope), findsNothing);
  });

  testWidgets('narrow window and empty list do not overflow or invent peers',
      (tester) async {
    await _pumpHome(tester, Brightness.dark, const Size(360, 640));
    expect(tester.takeException(), isNull);
    await _pumpHome(tester, Brightness.light, const Size(520, 480), rows: 0);
    expect(find.text('办公室电脑'), findsNothing);
    expect(find.text('输入对方 ID'), findsOneWidget);
    expect(find.text('示例设备'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('compact-home-footer')), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  Brightness brightness,
  Size size, {
  int rows = 24,
  double textScale = 1,
}) async {
  await _loadFixtureFonts(tester);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final password = CompactPasswordState.resolve(
    showOneTime: true,
    raw: 'fixture-secret',
    serviceStopped: false,
    revealed: false,
  );
  await tester.pumpWidget(MaterialApp(
    home: Theme(
      data: ThemeData(
        brightness: brightness,
        useMaterial3: false,
        fontFamily: 'FixtureSans',
        fontFamilyFallback: const ['FixtureCJK'],
      ),
      child: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQueryData(
                size: size, textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: RepaintBoundary(
                key: const Key('compact-home-shot'),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CompactHomeScaffold(
                    background: CompactHomeColors.of(context).page,
                    body: Column(
                      children: [
                        CompactConnectHeader(
                          field: TextField(
                            decoration: compactIdFieldDecoration(
                              context,
                              hint: '输入对方 ID',
                            ),
                          ),
                          connectLabel: '连接',
                          onConnect: () {},
                          fileLabel: '传输文件',
                          onFile: () {},
                          more: TextButton(
                            onPressed: () {},
                            child: const Text('更多'),
                          ),
                        ),
                        SizedBox(
                          height: 36,
                          child: CompactTabTrack(
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (var i = 0; i < _fixtureTabs.length; i++)
                                  CompactTabLabel(
                                    label: _fixtureTabs[i],
                                    selected: i == 0,
                                    onTap: () {},
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: rows == 0
                              ? const SizedBox.expand()
                              : ListView.builder(
                                  key: const Key('peer-list'),
                                  primary: false,
                                  itemCount: 16,
                                  itemBuilder: (context, index) {
                                    final peer = _fixturePeers[
                                        index % _fixturePeers.length];
                                    return CompactDeviceRow(
                                      icon: const Icon(
                                          Icons.desktop_windows_outlined),
                                      title: peer.$1,
                                      subtitle: peer.$2,
                                      online: peer.$3,
                                      actions: CompactPeerActions(
                                        connectLabel: '连接',
                                        fileLabel: '传输文件',
                                        onConnect: () {},
                                        onFile: () {},
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                    footer: CompactIdentityBar(
                      idLabel: 'ID',
                      idText: '123 456 789',
                      copyIdTip: 'Copy',
                      onCopyId: () {},
                      passwordLabel: '一次性密码',
                      password: password,
                      revealTip: 'Password',
                      onToggleReveal: () {},
                      copyPasswordTip: 'Copy',
                      onCopyPassword: () {},
                      refreshTip: 'Refresh',
                      onRefreshPassword: () {},
                      status: const Text('就绪'),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  ));
  await tester.pump();
  expect(tester.takeException(), isNull);
  final page = tester.widget<ColoredBox>(find.byType(ColoredBox).first).color;
  expect(
    page,
    brightness == Brightness.dark
        ? const Color(0xFF1A1C1F)
        : const Color(0xFFF4F5F7),
    reason: 'theme brightness=$brightness page=$page',
  );
  if (rows > 0) {
    expect(find.text('输入对方 ID'), findsOneWidget);
    expect(find.text('最近访问过'), findsOneWidget);
    expect(find.text('会议室'), findsOneWidget);
    expect(find.text('••••••'), findsOneWidget);
  }
  if (rows > 0 && size == const Size(800, 600) && textScale == 1) {
    await tester.runAsync(() async {
      try {
        await _saveFixtureShot(tester, brightness)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    });
  }
}

Future<void> _expectBarSurvivesScroll(WidgetTester tester, Size size) async {
  final footer = tester.getRect(find.byKey(const Key('compact-home-footer')));
  expect(footer.bottom, lessThanOrEqualTo(size.height + 1));
  await tester.drag(find.byKey(const Key('peer-list')), const Offset(0, -800));
  await tester.pump();
  expect(tester.takeException(), isNull);
  final after = tester.getRect(find.byKey(const Key('compact-home-footer')));
  expect(after.bottom, lessThanOrEqualTo(size.height + 1));
  final position = tester
      .state<ScrollableState>(find.descendant(
        of: find.byKey(const Key('peer-list')),
        matching: find.byType(Scrollable),
      ))
      .position;
  expect(position.pixels, greaterThan(0));
  expect(find.text('就绪'), findsOneWidget);
}

Future<void> _saveFixtureShot(
    WidgetTester tester, Brightness brightness) async {
  final dir = Directory('/opt/cursor/artifacts');
  if (!dir.existsSync()) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('compact-home-shot')),
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return;
  final name = brightness == Brightness.dark
      ? 'compact-home-fixture-dark.png'
      : 'compact-home-fixture-light.png';
  File('${dir.path}/$name').writeAsBytesSync(bytes.buffer.asUint8List());
}

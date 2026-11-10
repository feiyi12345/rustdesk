import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/desktop/widgets/compact_home.dart';

void main() {
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

  testWidgets('connect header fits 800 and a narrow window', (tester) async {
    Future<void> pump(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: 80,
            child: CompactConnectHeader(
              field: const TextField(
                decoration: InputDecoration(hintText: 'Enter Remote ID'),
              ),
              connectLabel: 'Connect',
              onConnect: () {},
              fileLabel: 'Transfer file',
              onFile: () {},
              more: const Text('More'),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    }

    await pump(const Size(800, 600));
    await pump(const Size(360, 480));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('narrow window and empty list do not overflow or invent peers',
      (tester) async {
    await _pumpHome(tester, Brightness.dark, const Size(520, 480), rows: 0);
    expect(find.text('Fixture peer'), findsNothing);
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
    theme: ThemeData(brightness: brightness),
    home: Builder(
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
                  notices:
                      const SizedBox(height: 36, child: Text('notice-fixture')),
                  body: rows == 0
                      ? const SizedBox.expand()
                      : ListView.builder(
                          key: const Key('peer-list'),
                          itemCount: rows,
                          itemBuilder: (context, index) => SizedBox(
                            height: 48,
                            child: Text('Fixture peer $index'),
                          ),
                        ),
                  footer: CompactIdentityBar(
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
                    status: const Text('status-fixture'),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  ));
  await tester.pump();
  expect(tester.takeException(), isNull);
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
  expect(find.text('Fixture peer 0'), findsNothing);
  expect(find.text('status-fixture'), findsOneWidget);
}

Future<void> _saveFixtureShot(
    WidgetTester tester, Brightness brightness) async {
  final dir = Directory('/opt/cursor/artifacts');
  if (!dir.existsSync()) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('compact-home-shot')),
  );
  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return;
  final name = brightness == Brightness.dark
      ? 'compact-home-fixture-dark.png'
      : 'compact-home-fixture-light.png';
  File('${dir.path}/$name').writeAsBytesSync(bytes.buffer.asUint8List());
}

import 'package:flutter/material.dart';

/// Desktop home is one column. Shared peer widgets look for this scope and
/// add shortcut actions without replacing their menus.
class CompactHomeScope extends InheritedWidget {
  const CompactHomeScope({super.key, required super.child});

  static bool isActive(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CompactHomeScope>() !=
        null;
  }

  @override
  bool updateShouldNotify(CompactHomeScope oldWidget) => false;
}

class CompactHomeColors {
  final Color page;
  final Color field;
  final Color raised;
  final Color line;
  final Color text;
  final Color muted;
  final Color connectBg;
  final Color connectFg;

  const CompactHomeColors({
    required this.page,
    required this.field,
    required this.raised,
    required this.line,
    required this.text,
    required this.muted,
    required this.connectBg,
    required this.connectFg,
  });

  factory CompactHomeColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const CompactHomeColors(
        page: Color(0xFF1A1C1F),
        field: Color(0xFF24262B),
        raised: Color(0xFF2E3136),
        line: Color(0x1FFFFFFF),
        text: Color(0xFFE6E6E6),
        muted: Color(0xFF9B9BA3),
        connectBg: Color(0xFFF2F0EC),
        connectFg: Color(0xFF1A1C1F),
      );
    }
    return const CompactHomeColors(
      page: Color(0xFFF4F5F7),
      field: Color(0xFFFFFFFF),
      raised: Color(0xFFE7E8EC),
      line: Color(0x1F000000),
      text: Color(0xFF1C1E22),
      muted: Color(0xFF5E6570),
      connectBg: Color(0xFF1C1E22),
      connectFg: Color(0xFFF7F7F5),
    );
  }
}

/// Notices stay above the list and scroll on their own. The footer stays
/// outside the list scroll, so a long peer list cannot push it off screen.
class CompactHomeScaffold extends StatelessWidget {
  const CompactHomeScaffold({
    super.key,
    required this.background,
    required this.body,
    this.notices,
    this.footer,
  });

  final Color background;
  final Widget? notices;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final noticeMax =
                    (constraints.maxHeight * 0.42).clamp(0.0, 320.0);
                return Column(
                  children: [
                    if (notices != null)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: noticeMax),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const ClampingScrollPhysics(),
                          children: [notices!],
                        ),
                      ),
                    Expanded(child: body),
                  ],
                );
              },
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class CompactPasswordState {
  final bool showActions;
  final String display;
  final String copyText;

  const CompactPasswordState({
    required this.showActions,
    required this.display,
    required this.copyText,
  });

  /// Eye, copy, and refresh follow the one-time password board: hidden for
  /// click approval, permanent-only, a stopped service, and the '-' placeholder.
  static CompactPasswordState resolve({
    required bool showOneTime,
    required String raw,
    required bool serviceStopped,
    required bool revealed,
  }) {
    final show = showOneTime && !serviceStopped && raw.isNotEmpty && raw != '-';
    return CompactPasswordState(
      showActions: show,
      display: !show ? '' : (revealed ? raw : '••••••'),
      copyText: raw,
    );
  }
}

class CompactIdentityBar extends StatelessWidget {
  const CompactIdentityBar({
    super.key,
    required this.idLabel,
    required this.idText,
    required this.copyIdTip,
    required this.onCopyId,
    required this.passwordLabel,
    required this.password,
    required this.revealTip,
    required this.onToggleReveal,
    required this.copyPasswordTip,
    required this.onCopyPassword,
    required this.refreshTip,
    required this.onRefreshPassword,
    this.editTip,
    this.onEditPassword,
    this.status,
  });

  final String idLabel;
  final String idText;
  final String copyIdTip;
  final VoidCallback onCopyId;
  final String passwordLabel;
  final CompactPasswordState password;
  final String revealTip;
  final VoidCallback onToggleReveal;
  final String copyPasswordTip;
  final VoidCallback onCopyPassword;
  final String refreshTip;
  final VoidCallback onRefreshPassword;
  final String? editTip;
  final VoidCallback? onEditPassword;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final colors = CompactHomeColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14);
    return Material(
      key: const Key('compact-home-footer'),
      color: colors.page,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720 || scale > 16;
              final id = _idCluster(colors);
              final pass = _passwordCluster(colors);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stacked)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        id,
                        if (password.showActions || onEditPassword != null)
                          pass,
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: id),
                        Flexible(child: pass),
                      ],
                    ),
                  if (status != null) status!,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _idCluster(CompactHomeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '$idLabel $idText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: colors.text),
          ),
        ),
        _iconButton(
          key: const Key('compact-id-copy'),
          tip: copyIdTip,
          icon: Icons.copy_rounded,
          onPressed: onCopyId,
          color: colors.muted,
        ),
      ],
    );
  }

  Widget _passwordCluster(CompactHomeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (password.showActions) ...[
          Flexible(
            child: Text(
              passwordLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              password.display,
              key: const Key('compact-password-display'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.text),
            ),
          ),
          _iconButton(
            key: const Key('compact-password-reveal'),
            tip: revealTip,
            icon: Icons.visibility_outlined,
            onPressed: onToggleReveal,
            color: colors.muted,
          ),
          _iconButton(
            key: const Key('compact-password-copy'),
            tip: copyPasswordTip,
            icon: Icons.copy_rounded,
            onPressed: onCopyPassword,
            color: colors.muted,
          ),
          _iconButton(
            key: const Key('compact-password-refresh'),
            tip: refreshTip,
            icon: Icons.refresh_rounded,
            onPressed: onRefreshPassword,
            color: colors.muted,
          ),
        ],
        if (onEditPassword != null)
          _iconButton(
            key: const Key('compact-password-edit'),
            tip: editTip ?? '',
            icon: Icons.edit_outlined,
            onPressed: onEditPassword,
            color: colors.muted,
          ),
      ],
    );
  }

  Widget _iconButton({
    required Key key,
    required String tip,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return IconButton(
      key: key,
      tooltip: tip,
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    );
  }
}

class CompactConnectHeader extends StatelessWidget {
  const CompactConnectHeader({
    super.key,
    required this.field,
    required this.connectLabel,
    required this.onConnect,
    required this.fileLabel,
    required this.onFile,
    this.more,
  });

  final Widget field;
  final String connectLabel;
  final VoidCallback onConnect;
  final String fileLabel;
  final VoidCallback onFile;
  final Widget? more;

  @override
  Widget build(BuildContext context) {
    final colors = CompactHomeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: field),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                key: const Key('compact-connect'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: colors.connectBg,
                  foregroundColor: colors.connectFg,
                  minimumSize: const Size(64, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onConnect,
                child: Text(
                  connectLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              key: const Key('compact-file'),
              style: _linkStyle(colors),
              onPressed: onFile,
              child: Text(
                fileLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (more != null) more!,
          ],
        ),
      ],
    );
  }

  ButtonStyle _linkStyle(CompactHomeColors colors) {
    return TextButton.styleFrom(
      foregroundColor: colors.muted,
      minimumSize: const Size(0, 32),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

InputDecoration compactIdFieldDecoration(
  BuildContext context, {
  required String? hint,
}) {
  final colors = CompactHomeColors.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: colors.line),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: colors.muted, fontSize: 14),
    filled: true,
    fillColor: colors.field,
    isDense: true,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.muted),
    ),
  );
}

ButtonStyle compactPeerActionStyle(CompactHomeColors colors) {
  return TextButton.styleFrom(
    foregroundColor: colors.text,
    minimumSize: const Size(0, 28),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    textStyle: const TextStyle(fontSize: 12),
  );
}

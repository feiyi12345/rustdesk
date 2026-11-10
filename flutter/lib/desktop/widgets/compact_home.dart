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

/// Text shown beside the incoming-only password actions. A real password is
/// never placed in the widget unless reveal is on.
String incomingPasswordVisibleText(CompactPasswordState state, String raw) {
  if (state.showActions) return state.display;
  if (raw == '-' || raw.isEmpty) return raw;
  return '';
}

class CompactPasswordActions extends StatelessWidget {
  const CompactPasswordActions({
    super.key,
    required this.password,
    required this.passwordLabel,
    required this.revealTip,
    required this.onToggleReveal,
    required this.copyTip,
    required this.onCopy,
    required this.refreshTip,
    required this.onRefresh,
    this.showLabel = true,
    this.editTip,
    this.onEdit,
  });

  final CompactPasswordState password;
  final bool showLabel;
  final String passwordLabel;
  final String revealTip;
  final VoidCallback onToggleReveal;
  final String copyTip;
  final VoidCallback onCopy;
  final String refreshTip;
  final VoidCallback onRefresh;
  final String? editTip;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = CompactHomeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (password.showActions) ...[
          if (showLabel)
            Flexible(
              child: Text(
                passwordLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: colors.muted),
              ),
            ),
          if (showLabel) const SizedBox(width: 6),
          if (showLabel)
            Flexible(
              child: Text(
                password.display,
                key: const Key('compact-password-display'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: colors.text),
              ),
            ),
          _glyphButton(
            key: const Key('compact-password-reveal'),
            tip: revealTip,
            icon: Icons.visibility_outlined,
            onPressed: onToggleReveal,
            color: colors.muted,
          ),
          _glyphButton(
            key: const Key('compact-password-copy'),
            tip: copyTip,
            icon: Icons.copy_rounded,
            onPressed: onCopy,
            color: colors.muted,
          ),
          _glyphButton(
            key: const Key('compact-password-refresh'),
            tip: refreshTip,
            icon: Icons.refresh_rounded,
            onPressed: onRefresh,
            color: colors.muted,
          ),
        ],
        if (onEdit != null)
          _glyphButton(
            key: const Key('compact-password-edit'),
            tip: editTip ?? '',
            icon: Icons.edit_outlined,
            onPressed: onEdit,
            color: colors.muted,
          ),
      ],
    );
  }
}

Widget _glyphButton({
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
              final pass = _passwordCluster();
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

  Widget _passwordCluster() {
    return CompactPasswordActions(
      password: password,
      passwordLabel: passwordLabel,
      revealTip: revealTip,
      onToggleReveal: onToggleReveal,
      copyTip: copyPasswordTip,
      onCopy: onCopyPassword,
      refreshTip: refreshTip,
      onRefresh: onRefreshPassword,
      editTip: editTip,
      onEdit: onEditPassword,
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

class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    super.key,
    required this.showBulkActions,
    required this.bulkActions,
    required this.trailing,
  });

  final bool showBulkActions;
  final List<Widget> bulkActions;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBulkActions)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: bulkActions),
            ),
          ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class CompactTabTrack extends StatelessWidget {
  const CompactTabTrack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = CompactHomeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}

class CompactTabLabel extends StatelessWidget {
  const CompactTabLabel({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = CompactHomeColors.of(context);
    return Tooltip(
      message: tooltip ?? label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? colors.raised : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? colors.text : colors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CompactPeerActions extends StatelessWidget {
  const CompactPeerActions({
    super.key,
    required this.connectLabel,
    required this.fileLabel,
    this.onConnect,
    this.onFile,
    this.trailing,
  });

  final String connectLabel;
  final String fileLabel;
  final VoidCallback? onConnect;
  final VoidCallback? onFile;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = compactPeerActionStyle(CompactHomeColors.of(context));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 72),
          child: TextButton(
            style: style,
            onPressed: onConnect,
            child: Text(
              connectLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 88),
          child: TextButton(
            style: style,
            onPressed: onFile,
            child: Text(
              fileLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class CompactDeviceRow extends StatelessWidget {
  const CompactDeviceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.online,
    required this.actions,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final bool online;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final colors = CompactHomeColors.of(context);
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(color: colors.muted, size: 22),
                child: icon,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: colors.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online
                      ? const Color(0xFF3DDC97)
                      : colors.muted.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              actions,
            ],
          ),
        ),
      ),
    );
  }
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

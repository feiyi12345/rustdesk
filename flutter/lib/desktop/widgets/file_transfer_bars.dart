import 'package:flutter/material.dart';

/// Filename search owned by the parent. Submit is whatever the parent passes;
/// this widget does not open a directory.
class FileNameSearchBar extends StatelessWidget {
  const FileNameSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 18),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
        suffixIcon: IconButton(
          tooltip: clearTooltip,
          icon: const Icon(Icons.close, size: 16),
          onPressed: () {
            controller.clear();
            onClear();
          },
        ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

class FileSearchEmptyHint extends StatelessWidget {
  const FileSearchEmptyHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// Directory selection and the OS pending queue are separate rows.
class TransferSelectionBar extends StatelessWidget {
  const TransferSelectionBar({
    super.key,
    required this.directoryCount,
    required this.pendingCount,
    required this.directoryLabel,
    required this.pendingLabel,
    required this.targetLabel,
    required this.clearDirectoryLabel,
    required this.clearPendingLabel,
    required this.onClearDirectory,
    required this.onClearPending,
  });

  final int directoryCount;
  final int pendingCount;
  final String directoryLabel;
  final String pendingLabel;
  final String targetLabel;
  final String clearDirectoryLabel;
  final String clearPendingLabel;
  final VoidCallback onClearDirectory;
  final VoidCallback onClearPending;

  @override
  Widget build(BuildContext context) {
    if (directoryCount == 0 && pendingCount == 0) {
      return const SizedBox.shrink();
    }
    final style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(targetLabel,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        if (directoryCount > 0)
          Row(
            children: [
              Expanded(
                child: Text(
                  directoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              TextButton(
                onPressed: onClearDirectory,
                child: Text(clearDirectoryLabel, style: style),
              ),
            ],
          ),
        if (pendingCount > 0)
          Row(
            children: [
              Expanded(
                child: Text(
                  pendingLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              TextButton(
                onPressed: onClearPending,
                child: Text(clearPendingLabel, style: style),
              ),
            ],
          ),
      ],
    );
  }
}

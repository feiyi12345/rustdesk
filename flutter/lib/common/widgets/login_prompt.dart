import 'package:flutter/material.dart';

/// Logged-out address book and device-group pane. Both pages use this
/// instead of an inline button so the empty state can be laid out without
/// the account model.
class LoginPromptButton extends StatelessWidget {
  const LoginPromptButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        key: const Key('login-prompt'),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

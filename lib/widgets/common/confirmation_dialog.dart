import 'package:flutter/material.dart';

/// A standardized confirmation dialog widget that provides consistent
/// styling across the app for destructive actions like deletion.
///
/// Automatically adapts to dark/light themes using the app's theme colors.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.isDestructive = true,
  });

  /// Shows a confirmation dialog and returns true if confirmed, false if cancelled.
  /// Returns null if dismissed by tapping outside.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    bool isDestructive = true,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.dialogTheme.backgroundColor,
      shape: theme.dialogTheme.shape,
      title: Text(title, style: theme.dialogTheme.titleTextStyle),
      content: Text(message, style: theme.dialogTheme.contentTextStyle),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: theme.colorScheme.error)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

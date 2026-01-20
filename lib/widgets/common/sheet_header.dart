import 'package:flutter/material.dart';

class SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final bool isPinned;
  final String? saveTooltip;
  final String? deleteTooltip;
  final String? pinTooltip;
  final String? unpinTooltip;

  const SheetHeader({
    super.key,
    required this.title,
    this.onSave,
    this.onDelete,
    this.onPin,
    this.isPinned = false,
    this.saveTooltip,
    this.deleteTooltip,
    this.pinTooltip,
    this.unpinTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Left-aligned title
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Right-aligned action buttons
          if (onPin != null)
            IconButton(
              icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: onPin,
              color: isPinned ? Colors.amber : null,
              tooltip: isPinned ? (unpinTooltip ?? 'Unpin') : (pinTooltip ?? 'Pin'),
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: deleteTooltip ?? 'Delete',
            ),
          if (onSave != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: onSave,
              tooltip: saveTooltip ?? 'Save',
            ),
        ],
      ),
    );
  }
}

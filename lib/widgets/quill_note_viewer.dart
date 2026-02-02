import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class QuillNoteViewer extends StatelessWidget {
  final String content;
  final int? maxLines;
  final TextOverflow? overflow;

  const QuillNoteViewer({
    super.key,
    required this.content,
    this.maxLines,
    this.overflow,
  });

  static String toPlainText(String content) {
    try {
      final doc = quill.Document.fromJson(jsonDecode(content));
      return doc.toPlainText().trim();
    } catch (e) {
      return content;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      // If used for preview (maxLines set), render as simple text
      if (maxLines != null) {
        final plainText = toPlainText(content);
        return Text(
          plainText,
          maxLines: maxLines,
          overflow: overflow ?? TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }

      quill.Document doc;
      try {
        final List<dynamic> json = jsonDecode(content);
        if (json.isEmpty) {
          doc = quill.Document()..insert(0, '\n');
        } else {
          // Validate structure
          final lastOp = json.last;
          if (lastOp is Map && lastOp.containsKey('insert')) {
            final data = lastOp['insert'];
            if (data is String && !data.endsWith('\n')) {
              lastOp['insert'] = '$data\n';
            }
          }
          doc = quill.Document.fromJson(json);
        }
      } catch (e) {
        doc = quill.Document()..insert(0, '$content\n');
      }

      final controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      return quill.QuillEditor.basic(controller: controller);
    } catch (e) {
      // Fallback for old markdown content or plain text
      return Text(
        content,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../screens/drawing_screen.dart';
import '../screens/voice_note_screen.dart';
import '../utils/extensions.dart';
import '../widgets/common/custom_text_field.dart';
import 'drawing_preview.dart';
import 'voice_player.dart';

class NoteSheet extends StatefulWidget {
  final Note? note;
  final List<String> colors;
  final String? template;

  const NoteSheet({super.key, this.note, required this.colors, this.template});

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedColor;
  late bool _isPinned;
  late bool _isFullWidth;
  late List<String> _imagePaths;
  late String? _drawingData;
  late String? _voiceNotePath;
  late List<String> _tags;

  final FocusNode _contentFocus = FocusNode();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize basic fields first
    if (widget.note != null) {
      _titleController = TextEditingController(text: widget.note!.title);
      _contentController = TextEditingController(text: widget.note!.content);
      _selectedColor = widget.note!.color;
      _isPinned = widget.note!.isPinned;
      _isFullWidth = widget.note!.isFullWidth;
      _imagePaths = List.from(widget.note!.imagePaths);
      _drawingData = widget.note!.drawingData;
      _voiceNotePath = widget.note!.voiceNotePath;
      _tags = List.from(widget.note!.tags);
    } else {
      _selectedColor = widget.colors.first;
      _isPinned = false;
      _isFullWidth = false;
      _imagePaths = [];
      _drawingData = null;
      _voiceNotePath = null;
      _tags = [];
      _titleController = TextEditingController();
      _contentController = TextEditingController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize template content after context is available
    if (widget.note == null &&
        widget.template != null &&
        _contentController.text.isEmpty) {
      _initializeFromTemplate();
    }
  }

  void _initializeFromTemplate() {
    final l10n = context.l10n;

    // Template-based initialization
    if (widget.template == 'shopping') {
      _titleController.text = l10n.templateShopping;
      _contentController.text = '- [ ] \n- [ ] \n- [ ] ';
    } else if (widget.template == 'todo') {
      _titleController.text = l10n.templateTodo;
      _contentController.text =
          '- [ ] ${l10n.templateTodoDesc}\n- [ ] \n- [ ] ';
    } else if (widget.template == 'meeting') {
      _titleController.text = l10n.templateMeeting;
      _contentController.text =
          '**${l10n.templateMeeting}**\n\n'
          '**Tarih:** ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\n\n'
          '**Katılımcılar:**\n- \n\n'
          '**Gündem:**\n- \n\n'
          '**Notlar:**\n\n'
          '**Aksiyon Maddeleri:**\n- [ ] ';
    }
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bgColor = theme.cardColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Top Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _save,
                  tooltip: l10n.save,
                ),
                Expanded(
                  child: Text(
                    widget.note == null ? l10n.newNote : l10n.editNote,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                  onPressed: () => setState(() => _isPinned = !_isPinned),
                  color: _isPinned ? Colors.amber : null,
                  tooltip: _isPinned ? l10n.unpin : l10n.pin,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete,
                  tooltip: l10n.delete,
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _save,
                  tooltip: l10n.save,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.noteTitle,
                      border: InputBorder.none,
                      hintStyle: Theme.of(
                        context,
                      ).inputDecorationTheme.hintStyle,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map(
                            (tag) => Chip(
                              label: Text(
                                '#$tag',
                                style: const TextStyle(fontSize: 13),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () =>
                                  setState(() => _tags.remove(tag)),
                              backgroundColor: theme.primaryColor.withAlpha(30),
                            ),
                          )
                          .toList(),
                    ),

                  // Add tag field
                  CustomTextField(
                    controller: _tagController,
                    hintText: l10n.addTag,
                    prefixIcon: const Icon(Icons.tag),
                    onSubmitted: (value) {
                      if (value.isNotEmpty && !_tags.contains(value)) {
                        setState(() => _tags.add(value));
                        _tagController.clear();
                      }
                    },
                  ),

                  const Divider(),

                  // Attachments
                  if (_imagePaths.isNotEmpty) ...[
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) => Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_imagePaths[index]),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _imagePaths.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_voiceNotePath != null) ...[
                    VoicePlayer(
                      path: _voiceNotePath!,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      onDelete: () => setState(() => _voiceNotePath = null),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_drawingData != null) ...[
                    GestureDetector(
                      onTap: _openDrawing,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withAlpha(50),
                          ),
                        ),
                        child: Row(
                          children: [
                            DrawingPreview(
                              drawingData: _drawingData!,
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.draw,
                                        color: Colors.purple,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.drawingAttached,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Düzenlemek için dokunun',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () =>
                                  setState(() => _drawingData = null),
                              tooltip: 'Çizimi Sil',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Content
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocus,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: l10n.noteContent,
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),

          // Bottom Toolbar
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Format toolbar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _toolButton(
                        Icons.format_bold,
                        () => _applyFormat('**', '**'),
                      ),
                      _toolButton(
                        Icons.format_italic,
                        () => _applyFormat('_', '_'),
                      ),
                      _toolButton(
                        Icons.format_strikethrough,
                        () => _applyFormat('~~', '~~'),
                      ),
                      const SizedBox(width: 8),
                      _toolButton(Icons.list, () => _applyFormat('- ', '')),
                      _toolButton(
                        Icons.check_box_outlined,
                        () => _applyFormat('- [ ] ', ''),
                      ),
                      const SizedBox(width: 8),
                      _toolButton(Icons.title, () => _applyFormat('# ', '')),
                      _toolButton(
                        Icons.format_quote,
                        () => _applyFormat('> ', ''),
                      ),
                    ],
                  ),
                ),
                // Action toolbar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _actionButton(Icons.image, l10n.addImage, _pickImage),
                      const SizedBox(width: 8),
                      _actionButton(Icons.draw, l10n.draw, _openDrawing),
                      const SizedBox(width: 8),
                      _actionButton(Icons.mic, l10n.voiceNote, _recordVoice),
                      const SizedBox(width: 8),
                      _actionButton(
                        Icons.palette,
                        l10n.color,
                        _showColorPicker,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _applyFormat(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.start < 0) return;

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix${text.substring(selection.start, selection.end)}$suffix',
    );

    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset:
            selection.start + prefix.length + (selection.end - selection.start),
      );
    });
    _contentFocus.requestFocus();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _imagePaths.add(image.path));
    }
  }

  Future<void> _openDrawing() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingScreen(initialData: _drawingData),
      ),
    );

    if (result != null) {
      setState(() => _drawingData = result);
    }
  }

  Future<void> _recordVoice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceNoteScreen(existingPath: _voiceNotePath),
      ),
    );

    if (result != null) {
      setState(() => _voiceNotePath = result);
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 100,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.colors.length,
          itemBuilder: (context, index) {
            final color = widget.colors[index];
            final isSelected = color == _selectedColor;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _hexToColor(color),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 3,
                        )
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty &&
        content.isEmpty &&
        _imagePaths.isEmpty &&
        _voiceNotePath == null &&
        _drawingData == null) {
      Navigator.pop(context);
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: title,
      content: content,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      color: _selectedColor,
      orderIndex: widget.note?.orderIndex ?? 0,
      isPinned: _isPinned,
      isFullWidth: _isFullWidth,
      imagePaths: _imagePaths,
      drawingData: _drawingData,
      voiceNotePath: _voiceNotePath,
      tags: _tags,
    );

    if (widget.note == null) {
      Provider.of<NoteProvider>(context, listen: false).addNote(note);
    } else {
      Provider.of<NoteProvider>(context, listen: false).updateNote(note);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.note != null) {
      final l10n = context.l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteNote),
          content: Text(l10n.deleteNoteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await Provider.of<NoteProvider>(
          context,
          listen: false,
        ).deleteNote(widget.note!);
        if (mounted) Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    _tagController.dispose();
    super.dispose();
  }
}

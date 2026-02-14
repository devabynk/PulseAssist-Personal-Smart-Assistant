import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/extensions.dart';
import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../screens/drawing_screen.dart';
import '../screens/voice_note_screen.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/sheet_handle.dart';
import '../widgets/common/sheet_header.dart'; // Import shared widget
import '../widgets/drawing_preview.dart';
import '../widgets/voice_player.dart';

class QuillNoteSheet extends StatefulWidget {
  final Note? note;
  final List<String> colors;
  final String? template;

  const QuillNoteSheet({
    super.key,
    this.note,
    required this.colors,
    this.template,
  });

  @override
  State<QuillNoteSheet> createState() => _QuillNoteSheetState();
}

class _QuillNoteSheetState extends State<QuillNoteSheet> {
  // ... (State variables remain the same)
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late String _selectedColor;
  late bool _isPinned;
  late bool _isFullWidth;
  late List<String> _imagePaths;
  late String? _drawingData;
  late String? _voiceNotePath;
  late List<String> _tags;
  bool _isToolbarExpanded = false;

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _editorFocus = FocusNode();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ... (Init logic remains the same)
    if (widget.note != null) {
      _titleController = TextEditingController(text: widget.note!.title);
      _selectedColor = widget.note!.color;
      _isPinned = widget.note!.isPinned;
      _isFullWidth = widget.note!.isFullWidth;
      _imagePaths = List.from(widget.note!.imagePaths);
      _drawingData = widget.note!.drawingData;
      _voiceNotePath = widget.note!.voiceNotePath;
      _tags = List.from(widget.note!.tags);

      try {
        final doc = quill.Document.fromJson(jsonDecode(widget.note!.content));
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = quill.QuillController.basic();
      }
    } else {
      _titleController = TextEditingController();
      _selectedColor = widget.colors.first;
      _isPinned = false;
      _isFullWidth = false;
      _imagePaths = [];
      _drawingData = null;
      _voiceNotePath = null;
      _tags = [];
      _quillController = quill.QuillController.basic();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.note == null &&
        widget.template != null &&
        _quillController.document.isEmpty()) {
      _initializeTemplate();
    }
  }

  void _initializeTemplate() {
    // ... (Keep existing template logic)
    final l10n = context.l10n;
    List<Map<String, dynamic>>? deltaOps;

    if (widget.template == 'shopping') {
      _titleController.text = l10n.templateShopping;
      deltaOps = [
        {'insert': l10n.templateShoppingDesc},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
        {'insert': '\n'},
        {'insert': l10n.shoppingItem1},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
        {'insert': l10n.shoppingItem2},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
        {'insert': l10n.shoppingItem3},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
        {'insert': ''},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ];
    } else if (widget.template == 'todo') {
      _titleController.text = l10n.templateTodo;
      deltaOps = [
        {'insert': l10n.templateTodoDesc},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
        {'insert': '\n'},
        {'insert': l10n.todoItem1},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
        {'insert': l10n.todoItem2},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
        {'insert': l10n.todoItem3},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
        {'insert': ''},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ];
    } else if (widget.template == 'meeting') {
      _titleController.text = l10n.templateMeeting;
      final today = DateTime.now();
      final dateStr =
          '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';
      deltaOps = [
        {
          'insert': '${l10n.meetingDate}: ',
          'attributes': {'bold': true},
        },
        {'insert': '$dateStr\n'},
        {'insert': '\n'},
        {
          'insert': '${l10n.meetingParticipants}:\n',
          'attributes': {'bold': true},
        },
        {'insert': '• '},
        {'insert': '\n\n'},
        {
          'insert': '${l10n.meetingAgenda}:\n',
          'attributes': {'bold': true},
        },
        {'insert': '1. '},
        {'insert': '\n\n'},
        {
          'insert': '${l10n.meetingNotes}:\n',
          'attributes': {'bold': true},
        },
        {'insert': '• '},
        {'insert': '\n\n'},
        {
          'insert': '${l10n.meetingActionItems}:\n',
          'attributes': {'bold': true},
        },
        {'insert': ''},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ];
    }

    if (deltaOps != null) {
      _quillController.document = quill.Document.fromJson(deltaOps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      height:
          MediaQuery.of(context).size.height *
          0.70, // Reduced from 0.92 to 0.70
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SheetHandle(), // Replaced
          // Top Toolbar
          SheetHeader(
            title: widget.note == null ? l10n.newNote : l10n.editNote,
            isPinned: _isPinned,
            onPin: () => setState(() => _isPinned = !_isPinned),
            onDelete: widget.note != null ? _delete : null,
            onSave: _save,
            pinTooltip: l10n.pin,
            unpinTooltip: l10n.unpin,
            deleteTooltip: l10n.delete,
            saveTooltip: l10n.save,
          ), // Replaced

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
                    focusNode: _titleFocus,
                    // Use standard titleLarge for notes, or adjusted if needed.
                    // Keeping titleLarge as it's the standard for notes usually, but reminders was too big.
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  if (_tags.isNotEmpty) _buildTags(theme),

                  // Add tag field
                  _buildTagInput(l10n),

                  const Divider(),

                  // Attachments
                  if (_imagePaths.isNotEmpty) _buildImages(),
                  if (_voiceNotePath != null) _buildVoiceNote(),
                  if (_drawingData != null) _buildDrawingPreview(l10n),

                  // Quill Editor
                  Container(
                    constraints: const BoxConstraints(minHeight: 120),
                    child: quill.QuillEditor.basic(
                      controller: _quillController,
                      focusNode: _editorFocus,
                      config: quill.QuillEditorConfig(
                        placeholder: l10n
                            .noteContent, // Key exists in arb? Yes, 'noteContent'
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Reduced from 200
                ],
              ),
            ),
          ),

          // Quill Toolbar
          _buildQuillToolbar(),

          // Action Toolbar
          _buildActionToolbar(l10n),
        ],
      ),
    );
  }

  Widget _buildTags(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags
          .map(
            (tag) => Chip(
              label: Text('#$tag', style: const TextStyle(fontSize: 13)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _tags.remove(tag)),
              backgroundColor: theme.primaryColor.withAlpha(30),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTagInput(AppLocalizations l10n) {
    return CustomTextField(
      controller: _tagController,
      hintText: l10n.addTag,
      prefixIcon: const Icon(Icons.tag),
      onSubmitted: (value) {
        if (value.isNotEmpty && !_tags.contains(value)) {
          setState(() => _tags.add(value));
          _tagController.clear();
        }
      },
    );
  }

  Widget _buildImages() {
    return Column(
      children: [
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
                    onTap: () => setState(() => _imagePaths.removeAt(index)),
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
    );
  }

  Widget _buildVoiceNote() {
    return Column(
      children: [
        VoicePlayer(
          path: _voiceNotePath!,
          isDark: Theme.of(context).brightness == Brightness.dark,
          onDelete: () => setState(() => _voiceNotePath = null),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDrawingPreview(AppLocalizations l10n) {
    return Column(
      children: [
        GestureDetector(
          onTap: _openDrawing,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withAlpha(50)),
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
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _drawingData = null),
                  tooltip: 'Çizimi Sil',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuillToolbar() {
    final l10n = context.l10n;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toolbar toggle button
          InkWell(
            onTap: () =>
                setState(() => _isToolbarExpanded = !_isToolbarExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isToolbarExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isToolbarExpanded ? l10n.hideTools : l10n.formattingTools,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (!_isToolbarExpanded) ...[
                    const Icon(Icons.format_bold, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.format_italic,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.format_list_bulleted,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expandable toolbar
          if (_isToolbarExpanded) ...[
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: quill.QuillSimpleToolbar(controller: _quillController),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionToolbar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _actionButton(Icons.image, l10n.addImage, _pickImage),
            const SizedBox(width: 8),
            _actionButton(Icons.draw, l10n.draw, _openDrawing),
            const SizedBox(width: 8),
            _actionButton(Icons.mic, l10n.voiceNote, _recordVoice),
            const SizedBox(width: 8),
            _actionButton(Icons.palette, l10n.color, _showColorPicker),
          ],
        ),
      ),
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

  Future<void> _pickImage() async {
    final l10n = context.l10n;
    const maxFileSize = 2 * 1024 * 1024; // 2MB
    const validImageExt = ['jpg', 'jpeg', 'png', 'webp'];

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.fileSizeError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final ext = image.path.split('.').last.toLowerCase();
      if (!validImageExt.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.fileFormatError(validImageExt.join(', '))),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

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
    if (result != null) setState(() => _drawingData = result);
  }

  Future<void> _recordVoice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceNoteScreen(existingPath: _voiceNotePath),
      ),
    );
    if (result != null) setState(() => _voiceNotePath = result);
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
                  color: Color(
                    int.parse(color.substring(1), radix: 16) + 0xFF000000,
                  ),
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
    if (!_quillController.document.toPlainText().endsWith('\n')) {
      _quillController.document.insert(_quillController.document.length, '\n');
    }
    final contentJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );

    if (title.isEmpty &&
        _quillController.document.isEmpty() &&
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
      content: contentJson,
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
    _quillController.dispose();
    _titleFocus.dispose();
    _editorFocus.dispose();
    _tagController.dispose();
    super.dispose();
  }
}

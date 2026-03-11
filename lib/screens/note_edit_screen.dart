import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/extensions.dart';
import '../l10n/app_localizations.dart';
import '../models/note.dart';

import '../providers/note_provider.dart';
import '../screens/drawing_screen.dart';
import '../screens/voice_note_screen.dart';
import '../widgets/drawing_preview.dart';
import '../widgets/voice_player.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;
  final List<String> colors;
  final String? template;

  const NoteEditScreen({
    super.key,
    this.note,
    required this.colors,
    this.template,
  });

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late String _selectedColor;
  late bool _isPinned;
  late bool _isFullWidth;
  late List<String> _imagePaths;
  late String? _drawingData;
  late String? _voiceNotePath;
  late List<String> _tags;

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _editorFocus = FocusNode();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

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

  // Convert hex string like '#RRGGBB' to Color
  Color _getBackgroundColor() {
    try {
      final hexCode = _selectedColor.replaceAll('#', '');
      return Color(int.parse(hexCode, radix: 16) | 0xFF000000);
    } catch (e) {
      return Theme.of(context).scaffoldBackgroundColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = _getBackgroundColor();
    final bgColor = isDark
        ? Color.alphaBlend(
            baseColor.withAlpha(50),
            theme
                .scaffoldBackgroundColor, // scaffold background in full screen to blend nicely
          )
        : baseColor;

    final fgColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black54;

    final lastEditedText = widget.note != null
        ? '${l10n.editNote} ${DateFormat('HH:mm').format(widget.note!.updatedAt)}' // todo properly translate edited time
        : '${l10n.editNote} ${DateFormat('HH:mm').format(DateTime.now())}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: fgColor),
            onPressed: _saveAndPop,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: fgColor,
              ),
              onPressed: () => setState(() => _isPinned = !_isPinned),
            ),
            IconButton(
              icon: Icon(Icons.palette_outlined, color: fgColor),
              onPressed: () => _showColorPicker(),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: fgColor,
                            ),
                        decoration: InputDecoration(
                          hintText: l10n.noteTitle,
                          border: InputBorder.none,
                          hintStyle: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(color: hintColor),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_editorFocus);
                        },
                      ),

                      // Editor Field
                      quill.QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _editorFocus,
                        config: quill.QuillEditorConfig(
                          placeholder: l10n.noteContent,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Attachments Section
                      if (_imagePaths.isNotEmpty) _buildImages(),
                      if (_voiceNotePath != null) _buildVoiceNote(),
                      if (_drawingData != null) _buildDrawingPreview(l10n),
                    ],
                  ),
                ),
              ),

              // Bottom Toolbar (Similar to Google Keep)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? theme.bottomAppBarTheme.color : bgColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? theme.dividerColor : Colors.black12,
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add_box_outlined, color: fgColor),
                          onPressed: () => _showAddAttachmentMenu(context),
                        ),
                        // IconButton(
                        //   icon: Icon(Icons.palette_outlined, color: fgColor),
                        //   onPressed: () => _showColorPicker(),
                        // ),
                        Expanded(
                          child: Text(
                            lastEditedText,
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: hintColor),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert, color: fgColor),
                          onPressed: _showMoreOptionsMenu,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAndPop() {
    _save();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildImages() {
    return Column(
      children: _imagePaths.asMap().entries.map((entry) {
        final index = entry.key;
        final path = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(path),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => setState(() => _imagePaths.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
              color: Colors.purple.withAlpha(20),
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
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Düzenlemek için dokunun', // todo translate
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _drawingData = null),
                  tooltip: 'Çizimi Sil', // todo translate
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showAddAttachmentMenu(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.attachmentCamera), // usually Take photo
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.addImage),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brush_outlined),
              title: Text(l10n.draw),
              onTap: () {
                Navigator.pop(context);
                _openDrawing();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_none_outlined),
              title: Text(l10n.voiceNote),
              onTap: () {
                Navigator.pop(context);
                _recordVoice();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptionsMenu() {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.delete),
              onTap: () {
                Navigator.pop(context);
                _delete();
              },
            ),
            // Tags, etc can be added here
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = context.l10n;
    const maxFileSize = 2 * 1024 * 1024; // 2MB
    const validImageExt = ['jpg', 'jpeg', 'png', 'webp'];

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
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
        height: 120, // Keep like keep's circular options
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
                      : Border.all(color: Colors.grey.withAlpha(80), width: 1),
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
    if (_isDisposed) return;
    final title = _titleController.text.trim();
    if (!_quillController.document.toPlainText().endsWith('\n')) {
      _quillController.document.insert(_quillController.document.length, '\n');
    }
    final contentJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );

    // Don't save empty notes without attachments
    if (title.isEmpty &&
        _quillController.document.isEmpty() &&
        _imagePaths.isEmpty &&
        _voiceNotePath == null &&
        _drawingData == null) {
      return;
    }

    // Don't save if content is just a newline and title is empty
    if (title.isEmpty &&
        _quillController.document.toPlainText().trim().isEmpty &&
        _imagePaths.isEmpty &&
        _voiceNotePath == null &&
        _drawingData == null) {
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
        if (mounted) {
          Navigator.pop(context); // Pop the screen completely right away
        }
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _titleController.dispose();
    _quillController.dispose();
    _titleFocus.dispose();
    _editorFocus.dispose();
    super.dispose();
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/extensions.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../widgets/drawing_preview.dart';
import '../widgets/quill_note_sheet.dart';
import '../widgets/quill_note_viewer.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NoteProvider>(context, listen: false).loadNotes();
    });
  }

  List<Note> get _filteredNotes {
    final notes = Provider.of<NoteProvider>(context).notes;
    final query = _searchController.text;

    var filtered = notes;

    if (_selectedFilter == 'pinned') {
      filtered = filtered.where((n) => n.isPinned).toList();
    } else if (_selectedFilter == 'images') {
      filtered = filtered.where((n) => n.imagePaths.isNotEmpty).toList();
    } else if (_selectedFilter == 'voice') {
      filtered = filtered.where((n) => n.voiceNotePath != null).toList();
    } else if (_selectedFilter == 'tags') {
      filtered = filtered.where((n) => n.tags.isNotEmpty).toList();
    }

    if (query.isEmpty) return filtered;
    return filtered.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase()) ||
          note.content.toLowerCase().contains(query.toLowerCase()) ||
          note.tags.any(
            (tag) => tag.toLowerCase().contains(query.toLowerCase()),
          );
    }).toList();
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.noteColors.first;
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse(hexCode, radix: 16) | 0xFF000000);
    } catch (e) {
      return AppColors.noteColors.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.searchNotes,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              )
            : Text(l10n.myNotes),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    const Text('🗂️'),
                    const SizedBox(width: 8),
                    Text(l10n.allNotes),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pinned',
                child: Row(
                  children: [
                    const Text('📌'),
                    const SizedBox(width: 8),
                    Text(l10n.pinned),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'images',
                child: Row(
                  children: [
                    const Text('🖼️'),
                    const SizedBox(width: 8),
                    Text(l10n.withImages),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'voice',
                child: Row(
                  children: [
                    const Text('🎤'),
                    const SizedBox(width: 8),
                    Text(l10n.voiceNotes),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'tags',
                child: Row(
                  children: [
                    const Text('🏷️'),
                    const SizedBox(width: 8),
                    Text(l10n.tagged),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Consumer<NoteProvider>(
          builder: (context, noteProvider, child) {
            if (noteProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              );
            }
            if (_filteredNotes.isEmpty) {
              return _buildEmptyState(l10n);
            }
            return _buildNotesList();
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showTemplateSelector(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: Text(
            l10n.newNote,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Theme.of(context).iconTheme.color?.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? l10n.noNotes : l10n.noteNotFound,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withAlpha(127),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addNoteHint,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withAlpha(77),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    final pinnedNotes = _filteredNotes.where((n) => n.isPinned).toList();
    final unpinnedNotes = _filteredNotes.where((n) => !n.isPinned).toList();

    return CustomScrollView(
      slivers: [
        if (pinnedNotes.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.push_pin, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Pinned',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          _buildNotesGrid(pinnedNotes),
          const SliverToBoxAdapter(child: Divider(height: 32)),
        ],
        if (unpinnedNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Others',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          _buildNotesGrid(unpinnedNotes),
        ],
      ],
    );
  }

  Widget _buildNotesGrid(List<Note> notes) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: 16,
      ),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteCard(note);
        },
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final color = _hexToColor(note.color);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Color.alphaBlend(color.withAlpha(60), Theme.of(context).cardColor)
        : color;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Dismissible(
      key: Key(note.id),
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.push_pin, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _togglePin(note);
          return false;
        }
        return await _confirmDelete(note);
      },
      child: GestureDetector(
        onTap: () => _showNoteSheet(context, note: note),
        onLongPress: () => _showNoteOptions(note),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: color.withAlpha(100), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned)
                    const Icon(Icons.push_pin, size: 14, color: Colors.amber),
                  if (note.imagePaths.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.image,
                      size: 14,
                      color: textColor.withAlpha(150),
                    ),
                  ],
                  if (note.voiceNotePath != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.mic, size: 14, color: textColor.withAlpha(150)),
                  ],
                  if (note.drawingData != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.draw, size: 14, color: textColor.withAlpha(150)),
                  ],
                  const Spacer(),
                ],
              ),
              if (note.isPinned ||
                  note.imagePaths.isNotEmpty ||
                  note.voiceNotePath != null ||
                  note.drawingData != null)
                const SizedBox(height: 8),

              if (note.title.isNotEmpty) ...[
                Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              if (note.imagePaths.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(note.imagePaths.first),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (note.drawingData != null) ...[
                DrawingPreview(
                  drawingData: note.drawingData!,
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
              ],

              QuillNoteViewer(
                content: note.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),

              // Text(note.content, maxLines: 6),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: note.tags
                      .take(3)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: textColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withAlpha(180),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  DateFormat(
                    'dd MMM',
                    Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    ).locale.languageCode,
                  ).format(note.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withAlpha(150),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePin(Note note) async {
    await Provider.of<NoteProvider>(
      context,
      listen: false,
    ).updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  Future<bool> _confirmDelete(Note note) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: l10n.deleteNote,
      message: l10n.deleteNoteConfirm,
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
    );

    if (!mounted) return confirmed ?? false;

    if (confirmed == true) {
      await Provider.of<NoteProvider>(context, listen: false).deleteNote(note);
    }
    return confirmed ?? false;
  }

  void _showNoteOptions(Note note) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(note.isPinned ? l10n.unpin : l10n.pin),
              onTap: () {
                Navigator.pop(context);
                _togglePin(note);
              },
            ),
            ListTile(
              leading: Icon(
                note.isFullWidth ? Icons.width_normal : Icons.width_full,
              ),
              title: Text(note.isFullWidth ? 'Normal Width' : 'Full Width'),
              onTap: () async {
                Navigator.pop(context);
                await Provider.of<NoteProvider>(
                  context,
                  listen: false,
                ).updateNote(note.copyWith(isFullWidth: !note.isFullWidth));
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l10n.share),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelector(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.chooseTemplate,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTemplateOption(
              context,
              icon: Icons.note,
              title: l10n.templateBlank,
              subtitle: l10n.templateBlankDesc,
              onTap: () {
                Navigator.pop(context);
                _showNoteSheet(context);
              },
            ),
            _buildTemplateOption(
              context,
              icon: Icons.shopping_cart,
              title: l10n.templateShopping,
              subtitle: l10n.templateShoppingDesc,
              onTap: () {
                Navigator.pop(context);
                _showNoteSheet(context, template: 'shopping');
              },
            ),
            _buildTemplateOption(
              context,
              icon: Icons.check_box,
              title: l10n.templateTodo,
              subtitle: l10n.templateTodoDesc,
              onTap: () {
                Navigator.pop(context);
                _showNoteSheet(context, template: 'todo');
              },
            ),
            _buildTemplateOption(
              context,
              icon: Icons.meeting_room,
              title: l10n.templateMeeting,
              subtitle: l10n.templateMeetingDesc,
              onTap: () {
                Navigator.pop(context);
                _showNoteSheet(context, template: 'meeting');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }

  Future<void> _showNoteSheet(
    BuildContext context, {
    Note? note,
    String? template,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuillNoteSheet(
        note: note,
        colors: AppColors.noteColors
            .map(
              (c) =>
                  '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
            )
            .toList(),
        template: template,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Note sheet will be in next message due to length

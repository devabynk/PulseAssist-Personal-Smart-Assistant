import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/extensions.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/drawing_screen.dart';
import '../screens/flashcard_screen.dart';
import '../screens/note_edit_screen.dart';
import '../screens/voice_note_screen.dart';
import '../services/ai/ai_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../widgets/drawing_preview.dart';
import '../widgets/quill_note_viewer.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isSearching = false;
  bool _isGridView = true;
  bool _tabletInitialized = false;
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
    final q = _normalize(query);
    return filtered.where((note) {
      return _normalize(note.title).contains(q) ||
          _normalize(_extractPlainText(note.content)).contains(q) ||
          note.tags.any((tag) => _normalize(tag).contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isTablet = context.isTablet || context.isDesktop;

    // Auto-enable grid on first tablet render
    if (isTablet && !_tabletInitialized) {
      _tabletInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isGridView) setState(() => _isGridView = true);
      });
    }

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
        scrolledUnderElevation: 0,
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
          if (!isTablet)
            IconButton(
              icon: Icon(
                _isGridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
              ),
              tooltip: _isGridView ? l10n.gridView : l10n.listView,
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            _buildFilterChips(l10n),
            Expanded(
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
          ],
        ),
      ),
      bottomNavigationBar: _buildQuickAddBar(l10n),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    final filters = <(String, String, IconData)>[
      ('all', l10n.allNotes, Icons.notes_rounded),
      ('pinned', l10n.pinned, Icons.push_pin_rounded),
      ('images', l10n.withImages, Icons.image_rounded),
      ('voice', l10n.voiceNotes, Icons.mic_rounded),
      ('tags', l10n.tagged, Icons.tag_rounded),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        separatorBuilder: (context, index) =>const SizedBox(width: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (value, label, icon) = filters[index];
          final isSelected = _selectedFilter == value;
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).iconTheme.color?.withAlpha(180),
                ),
                const SizedBox(width: 4),
                Text(label),
              ],
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            selectedColor: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).cardColor,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : Theme.of(context).dividerColor.withAlpha(40),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            onSelected: (_) => setState(() => _selectedFilter = value),
          );
        },
      ),
    );
  }

  Widget _buildQuickAddBar(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.bottomAppBarTheme.color : theme.cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? theme.dividerColor : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showNoteSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.scaffoldBackgroundColor
                          : Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.newNote,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.check_box_outlined, color: theme.hintColor),
                onPressed: () => _showNoteSheet(context, template: 'todo'),
              ),
              IconButton(
                icon: Icon(Icons.mic_none, color: theme.hintColor),
                onPressed: () async {
                  final result = await Navigator.push<Map<String, String>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VoiceNoteScreen(),
                    ),
                  );
                  if (result != null && mounted) {
                    _saveQuickNote(
                      voiceNotePath: result['path'],
                      title: result['title'] ?? '',
                      description: result['description'] ?? '',
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.draw_outlined, color: theme.hintColor),
                onPressed: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DrawingScreen(),
                    ),
                  );
                  if (result != null && mounted) {
                    _saveQuickNote(drawingData: result);
                  }
                },
              ),
            ],
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withAlpha(127),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addNoteHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        if (pinnedNotes.isNotEmpty) _buildNotesGrid(pinnedNotes),
        if (unpinnedNotes.isNotEmpty) _buildNotesGrid(unpinnedNotes),
      ],
    );
  }

  Widget _buildNotesGrid(List<Note> notes) {
    final padding = EdgeInsets.fromLTRB(
      context.horizontalPadding,
      16,
      context.horizontalPadding,
      80,
    );
    if (_isGridView) {
      return SliverPadding(
        padding: padding,
        sliver: SliverMasonryGrid.count(
          crossAxisCount: context.gridColumns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childCount: notes.length,
          itemBuilder: (context, index) => _buildNoteCard(notes[index]),
        ),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: notes.length,
        itemBuilder: (context, index) => _buildNoteCard(notes[index]),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorHex = note.color.replaceAll('#', '');
    Color baseColor;
    try {
      baseColor = Color(int.parse(colorHex, radix: 16) + 0xFF000000);
    } catch (_) {
      baseColor = Colors.transparent;
    }

    // Google Keep style color calculation:
    // Light mode: Vibrant but readable (we use the base color, maybe slightly lightened)
    // Dark mode: Dark grey/surface color gently tinted with the base color (matte)
    final cardColor = isDark
        ? Color.alphaBlend(
            baseColor.withAlpha(isDark ? 50 : 255), // Matte tint on dark mode
            Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
          )
        : baseColor;

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
                ? Border.all(color: baseColor.withAlpha(100), width: 1)
                : Border.all(color: Colors.black.withAlpha(15), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // attachment icons row - only show if there are attachments (not pin)
                  if (note.imagePaths.isNotEmpty ||
                      note.voiceNotePath != null ||
                      note.drawingData != null) ...[
                    Row(
                      children: [
                        if (note.imagePaths.isNotEmpty)
                          Icon(
                            Icons.image,
                            size: 14,
                            color: textColor.withAlpha(150),
                          ),
                        if (note.voiceNotePath != null) ...[
                          if (note.imagePaths.isNotEmpty)
                            const SizedBox(width: 4),
                          Icon(
                            Icons.mic,
                            size: 14,
                            color: textColor.withAlpha(150),
                          ),
                        ],
                        if (note.drawingData != null) ...[
                          if (note.imagePaths.isNotEmpty ||
                              note.voiceNotePath != null)
                            const SizedBox(width: 4),
                          Icon(
                            Icons.draw,
                            size: 14,
                            color: textColor.withAlpha(150),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // add top padding if pinned and no attachments shown (to avoid overlap with pin icon)
                  if (note.isPinned &&
                      note.imagePaths.isEmpty &&
                      note.voiceNotePath == null &&
                      note.drawingData == null)
                    const SizedBox(height: 4),

                  if (note.title.isNotEmpty) ...[
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: textColor.withAlpha(180)),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor.withAlpha(150),
                      ),
                    ),
                  ),
                ],
              ),
              // Pin indicator top-right
              if (note.isPinned)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: Colors.amber,
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
              leading: const Icon(Icons.share_rounded),
              title: Text(l10n.shareNote),
              onTap: () {
                Navigator.pop(context);
                _shareNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.style_rounded),
              title: Text(l10n.flashcardMode),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlashcardScreen(note: note),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: Text(l10n.aiAutoTag),
              onTap: () {
                Navigator.pop(context);
                _autoTagNote(note);
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

  void _shareNote(Note note) {
    final plain = _extractPlainText(note.content);
    final text = note.title.isNotEmpty
        ? '${note.title}\n\n$plain'
        : plain;
    SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _autoTagNote(Note note) async {
    final l10n = context.l10n;
    final isTurkish =
        Provider.of<SettingsProvider>(context, listen: false)
                .locale
                .languageCode ==
            'tr';

    final groqProvider = AiManager.instance.groqProvider;
    if (!groqProvider.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noInternetForAi),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.aiTagging),
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final plain = _extractPlainText(note.content);
    final newTags = await groqProvider.generateTags(
      title: note.title,
      content: plain,
      isTurkish: isTurkish,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (newTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noTagsGenerated),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Merge with existing tags (avoid duplicates)
    final merged = {...note.tags, ...newTags}.toList();
    await Provider.of<NoteProvider>(context, listen: false)
        .updateNote(note.copyWith(tags: merged));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.aiTagsAdded(newTags.length)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveQuickNote({
    String? voiceNotePath,
    String? drawingData,
    String title = '',
    String description = '',
  }) {
    final now = DateTime.now();
    final contentOps = description.isNotEmpty
        ? [
            {'insert': description},
            {'insert': '\n'},
          ]
        : [
            {'insert': '\n'},
          ];
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      content: jsonEncode(contentOps),
      createdAt: now,
      updatedAt: now,
      color: '',
      orderIndex: 0,
      isPinned: false,
      isFullWidth: false,
      imagePaths: [],
      drawingData: drawingData,
      voiceNotePath: voiceNotePath,
      tags: [],
    );
    Provider.of<NoteProvider>(context, listen: false).addNote(note);
  }

  Future<void> _showNoteSheet(
    BuildContext context, {
    Note? note,
    String? template,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          note: note,
          colors: [
            '', // empty = "no color" (uses scaffold background, same as reminder sheet)
            ...AppColors.noteColors.map(
              (c) =>
                  '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
            ),
          ],
          template: template,
        ),
      ),
    );
  }

  /// TR/EN locale-aware lowercase normalization (handles İ→i, I→ı mapping)
  String _normalize(String s) {
    return s
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ü', 'ü')
        .toLowerCase();
  }

  /// Extract plain text from Quill delta JSON for searching
  String _extractPlainText(String contentJson) {
    try {
      final ops = jsonDecode(contentJson) as List<dynamic>;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString();
    } catch (_) {
      return contentJson;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Note sheet will be in next message due to length

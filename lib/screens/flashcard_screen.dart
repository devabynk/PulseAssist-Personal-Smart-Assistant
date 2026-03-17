import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/utils/extensions.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class FlashcardScreen extends StatefulWidget {
  final Note note;

  const FlashcardScreen({super.key, required this.note});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late final List<_Flashcard> _cards;
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _cards = _parseCards(widget.note);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_Flashcard> _parseCards(Note note) {
    final paragraphs = _extractParagraphs(note.content);
    if (paragraphs.isEmpty) return [];

    return paragraphs.asMap().entries.map((e) {
      final text = e.value.trim();
      // Front: first sentence or first 80 chars
      final firstSentenceEnd = text.indexOf(RegExp(r'[.!?\n]'));
      final front = firstSentenceEnd > 0 && firstSentenceEnd < text.length - 1
          ? text.substring(0, firstSentenceEnd + 1).trim()
          : (text.length > 80 ? '${text.substring(0, 80)}…' : text);
      return _Flashcard(
        front: front == text ? '${widget.note.title} — ${e.key + 1}' : front,
        back: text,
      );
    }).toList();
  }

  List<String> _extractParagraphs(String contentJson) {
    try {
      final ops = jsonDecode(contentJson) as List<dynamic>;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      final fullText = buffer.toString();
      return fullText
          .split(RegExp(r'\n{2,}'))
          .map((p) => p.trim())
          .where((p) => p.length > 10)
          .toList();
    } catch (_) {
      return contentJson
          .split(RegExp(r'\n{2,}'))
          .map((p) => p.trim())
          .where((p) => p.length > 10)
          .toList();
    }
  }

  void _goTo(int index) {
    if (index < 0 || index >= _cards.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.flashcardMode),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.style_outlined,
                    size: 64, color: Theme.of(context).hintColor),
                const SizedBox(height: 16),
                Text(
                  l10n.noFlashcardsHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.flashcardMode),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                l10n.cardOf(_currentIndex + 1, _cards.length),
                style: TextStyle(
                    color: Theme.of(context).hintColor, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _cards.length,
              backgroundColor: Theme.of(context).dividerColor.withAlpha(40),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _cards.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) =>
                    _FlipCard(card: _cards[index]),
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    onPressed: _currentIndex > 0
                        ? () => _goTo(_currentIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: _currentIndex > 0
                          ? Theme.of(context).cardColor
                          : Theme.of(context).disabledColor.withAlpha(30),
                      foregroundColor: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color,
                    ),
                  ),
                  Text(
                    l10n.swipeToNavigate,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                  IconButton.filled(
                    onPressed: _currentIndex < _cards.length - 1
                        ? () => _goTo(_currentIndex + 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: _currentIndex < _cards.length - 1
                          ? Theme.of(context).cardColor
                          : Theme.of(context).disabledColor.withAlpha(30),
                      foregroundColor: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Flashcard {
  final String front;
  final String back;
  const _Flashcard({required this.front, required this.back});
}

class _FlipCard extends StatefulWidget {
  final _Flashcard card;
  const _FlipCard({required this.card});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card != widget.card) {
      _controller.reset();
      setState(() => _isFront = true);
    }
  }

  void _flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _flip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * math.pi;
            final showFront = angle <= math.pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showFront
                  ? _CardFace(
                      text: widget.card.front,
                      isFront: true,
                      hint: l10n.tapToReveal,
                      isDark: isDark,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _CardFace(
                        text: widget.card.back,
                        isFront: false,
                        hint: '',
                        isDark: isDark,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final bool isFront;
  final String hint;
  final bool isDark;

  const _CardFace({
    required this.text,
    required this.isFront,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isFront
            ? (isDark
                ? AppColors.primary.withAlpha(30)
                : AppColors.primary.withAlpha(15))
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFront
              ? AppColors.primary.withAlpha(60)
              : Theme.of(context).dividerColor.withAlpha(40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFront ? Icons.style_rounded : Icons.check_circle_outline_rounded,
            color: isFront ? AppColors.primary : const Color(0xFF4CAF50),
            size: 32,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isFront ? 20 : 16,
                fontWeight:
                    isFront ? FontWeight.w600 : FontWeight.normal,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.6,
              ),
            ),
          ),
          if (isFront && hint.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              hint,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).hintColor),
            ),
          ],
        ],
      ),
    );
  }
}

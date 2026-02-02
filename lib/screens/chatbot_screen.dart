import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/message.dart';
import '../providers/alarm_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/note_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/extensions.dart';
import '../utils/responsive.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Note: Local _messages list is removed in favor of Consumer

  @override
  void initState() {
    super.initState();
    // Messages are loaded in Provider constructor or we can trigger it
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstRun());
  }

  Future<void> _checkFirstRun() async {
    final l10n = context.l10n;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Wait for settings to be loaded
    if (!settings.isLoaded) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    final isTurkish = settings.locale.languageCode == 'tr';

    // If there's already an active conversation with messages, don't do anything
    if (chatProvider.messages.isNotEmpty) {
      return;
    }

    // If there are conversations but no active one (unlikely after our fix), also return
    if (chatProvider.conversations.isNotEmpty &&
        chatProvider.activeConversation != null) {
      return;
    }

    // Only show welcome message if truly fresh start (no conversations ever)
    if (chatProvider.conversations.isEmpty) {
      // Start a conversation for the welcome message
      await chatProvider.startNewConversation(
        title: l10n.newChat,
        addWelcomeMessage: false,
        isTurkish: isTurkish,
        userName: settings.userName,
      );

      String welcomeMsg;

      // Only ask for name if we haven't asked before AND no name is set
      if (!settings.hasAskedForName && settings.userName == null) {
        welcomeMsg = isTurkish
            ? 'Merhaba! Ben Mina, senin kişisel asistanınım. 🌟\n\nSana nasıl hitap etmemi istersin?'
            : "Hello! I'm Mina, your personal assistant. 🌟\n\nHow should I call you?";
        // Mark that we've asked for name
        await settings.setHasAskedForName(true);
      } else {
        // We have a name or already asked, just greet
        final name = settings.userName ?? '';
        if (name.isNotEmpty) {
          welcomeMsg = isTurkish
              ? 'Merhaba $name! 👋 Bugün sana nasıl yardımcı olabilirim?'
              : 'Hello $name! 👋 How can I help you today?';
        } else {
          welcomeMsg = isTurkish
              ? 'Merhaba! 👋 Bugün sana nasıl yardımcı olabilirim?'
              : 'Hello! 👋 How can I help you today?';
        }
      }

      await chatProvider.addSystemMessage(
        welcomeMsg,
        chatProvider.activeConversation?.id,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    // Get current locale and user name
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isTurkish = settings.locale.languageCode == 'tr';
    final userName = settings.userName;

    await Provider.of<ChatProvider>(context, listen: false).sendMessage(
      text,
      isTurkish: isTurkish,
      userName: userName,
      settings: settings,
      l10n: context.l10n,
      alarmProvider: Provider.of<AlarmProvider>(context, listen: false),
      noteProvider: Provider.of<NoteProvider>(context, listen: false),
      reminderProvider: Provider.of<ReminderProvider>(context, listen: false),
      weatherProvider: Provider.of<WeatherProvider>(context, listen: false),
    );

    // Scroll handled by consumer update usually, or force it here
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chatProvider.activeConversation?.title ?? l10n.chatbot,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.online,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: l10n.newChat,
            onPressed: () {
              final settings = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              Provider.of<ChatProvider>(
                context,
                listen: false,
              ).startNewConversation(
                isTurkish: settings.locale.languageCode == 'tr',
                title: l10n.newChat,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => _showHistorySheet(context),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final messages = chatProvider.messages;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messages.isEmpty) {
            return Center(
              child: Text(
                l10n.startConversation,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  // Add 1 to itemCount when typing to show indicator
                  itemCount: messages.length + (chatProvider.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator at the end
                    if (chatProvider.isTyping && index == messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(messages[index]);
                  },
                ),
              ),
              _buildQuickReplies(l10n),
              _buildInputArea(l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickReplies(AppLocalizations l10n) {


    final chips = [
      l10n.qaAlarm,
      l10n.qaReminder,
      l10n.qaNote,
      l10n.qaPharmacy,
      l10n.qaEvents,
    ];

    // Icons for each chip type
    final icons = [
      Icons.alarm,
      Icons.notification_important,
      Icons.edit_note,
      Icons.local_pharmacy,
      Icons.event,
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(chips[index]),
            backgroundColor: Theme.of(context).cardColor,
            labelStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 13,
            ),
            avatar: Icon(icons[index], size: 16, color: AppColors.primary),
            onPressed: () {
              _controller.text = chips[index];
              _sendMessage();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(50),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Dikey ortalama
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (chatProvider.attachmentPath != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8, left: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                chatProvider.attachmentType == 'image'
                                    ? Icons.image
                                    : (chatProvider.attachmentType == 'audio'
                                          ? Icons.mic
                                          : Icons.insert_drive_file),
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                child: Text(
                                  chatProvider.attachmentPath!.split('/').last,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => chatProvider.clearAttachment(),
                                child: const Icon(Icons.close, size: 16),
                              ),
                            ],
                          ),
                        ),
                      // TextField with + button inside using Material for better border rendering
                      Material(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withAlpha(
                                    204,
                                  ) // Çok daha belirgin beyaz
                                : Colors.black.withAlpha(
                                    153,
                                  ), // Çok daha belirgin siyah
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                maxLines: 4,
                                minLines: 1,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.typeMessage,
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).hintColor,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  isCollapsed: true,
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            // + button inside the text field, aligned to the right
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).primaryColor,
                              onPressed: () => _showAttachmentOptions(context),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.attachmentOptions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: Text(l10n.attachmentImageGallery),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).pickAttachment('image', context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.purple),
                title: Text(l10n.attachmentCamera),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).pickAttachment('camera', context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic, color: Colors.red),
                title: Text(l10n.attachmentAudio),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).pickAttachment('audio', context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.insert_drive_file,
                  color: Colors.orange,
                ),
                title: Text(l10n.attachmentDocument),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).pickAttachment('file', context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final l10n = context.l10n;
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.conversationHistory,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (chatProvider.conversations.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        label: Text(
                          l10n.clearHistory,
                          style: const TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          // Handle Clear All
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.clearHistory),
                              content: Text(l10n.clearHistoryConfirm),
                              actions: [
                                TextButton(
                                  child: Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).cancelButtonLabel,
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                                TextButton(
                                  child: Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).deleteButtonTooltip,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    chatProvider.clearAllHistory();
                                    Navigator.pop(ctx); // Close Dialog
                                    Navigator.pop(context); // Close Sheet
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: chatProvider.conversations.isEmpty
                        ? Center(child: Text(l10n.noHistory))
                        : ListView.builder(
                            itemCount: chatProvider.conversations.length,
                            itemBuilder: (context, index) {
                              final conv = chatProvider.conversations[index];
                              final isSelected =
                                  conv.id ==
                                  chatProvider.activeConversation?.id;
                              return ListTile(
                                title: Text(
                                  conv.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  conv.lastMessageAt.toString().substring(
                                    0,
                                    16,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.chat_bubble_outline,
                                  color: isSelected ? AppColors.primary : null,
                                ),
                                selected: isSelected,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    chatProvider.deleteConversation(conv.id);
                                  },
                                ),
                                onTap: () {
                                  chatProvider.selectConversation(conv.id);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    final maxWidth = Responsive.chatBubbleMaxWidth(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser ? null : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachmentPath != null &&
                      message.attachmentType == 'image')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(message.attachmentPath!),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  if (message.attachmentPath != null &&
                      message.attachmentType != 'image')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            message.attachmentType == 'audio'
                                ? Icons.mic
                                : Icons.insert_drive_file,
                            size: 20,
                            color: isUser ? Colors.white70 : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.attachmentPath!.split('/').last,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: isUser ? Colors.white70 : Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    onTapLink: (text, href, title) async {
                      if (href != null) {
                        try {
                          final uri = Uri.parse(href);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            // Try processing as tel: or other schemes explicitly if needed
                            await launchUrl(uri);
                          }
                        } catch (e) {
                          debugPrint('Error launching URL: $e');
                        }
                      }
                    },
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 15,
                      ),
                      a: TextStyle(
                        color: isUser ? Colors.white : Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                      // Ensure lists and headers look good
                      listBullet: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 150),
                SizedBox(width: 4),
                _TypingDot(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              Theme.of(context).disabledColor,
              Theme.of(context).primaryColor,
              _animation.value,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

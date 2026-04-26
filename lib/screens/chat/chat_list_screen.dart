import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  String? _selectedFolder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final chatService = context.read<ChatService>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Conversations',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _isSearching = !_isSearching),
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: AppColors.primary,
                      ),
                    ),
                    _buildNewChatButton(context, chatService),
                  ],
                ),
              ),

              // Search bar
              if (_isSearching)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

              // Folders
              if (user != null)
                SizedBox(
                  height: 44,
                  child: StreamBuilder<List<FolderModel>>(
                    stream: chatService.getUserFolders(user.uid),
                    builder: (context, snap) {
                      final folders = snap.data ?? [];
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _folderChip('All', null, isDark),
                          ...folders
                              .map((f) => _folderChip(f.name, f.id, isDark)),
                          _addFolderChip(context, chatService, user.uid, isDark),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              // Conversation List
              Expanded(
                child: user == null
                    ? const Center(child: Text('Please sign in'))
                    : StreamBuilder<List<ConversationModel>>(
                        stream: _selectedFolder != null
                            ? chatService.getFolderConversations(
                                user.uid, _selectedFolder!)
                            : chatService.getUserConversations(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          var conversations = snapshot.data ?? [];

                          // Apply search filter
                          if (_searchQuery.isNotEmpty) {
                            final q = _searchQuery.toLowerCase();
                            conversations = conversations
                                .where((c) =>
                                    c.title.toLowerCase().contains(q) ||
                                    (c.lastMessage
                                            ?.toLowerCase()
                                            .contains(q) ??
                                        false))
                                .toList();
                          }

                          if (conversations.isEmpty) {
                            return _buildEmpty();
                          }

                          return ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: conversations.length,
                            itemBuilder: (context, i) => _buildConvTile(
                                conversations[i], isDark, chatService),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _folderChip(String name, String? id, bool isDark) {
    final isSelected = _selectedFolder == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFolder = id),
        child: Chip(
          label: Text(name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white60,
              )),
          backgroundColor: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : AppColors.lightCardLight),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }

  Widget _addFolderChip(
      BuildContext context, ChatService service, String uid, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _showCreateFolder(context, service, uid),
        child: Chip(
          avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
          label: const Text('New Folder',
              style: TextStyle(fontSize: 13, color: AppColors.primary)),
          backgroundColor: AppColors.primary.withOpacity(0.08),
          side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 2),
        ),
      ),
    );
  }

  Widget _buildConvTile(
      ConversationModel conv, bool isDark, ChatService chatService) {
    Color modelColor;
    switch (conv.model) {
      case AIModel.claude:
        modelColor = AppColors.claudeColor;
        break;
      case AIModel.gpt4:
        modelColor = AppColors.gptColor;
        break;
      case AIModel.gemini:
        modelColor = AppColors.geminiColor;
        break;
      case AIModel.custom:
        modelColor = AppColors.customColor;
        break;
    }

    return Dismissible(
      key: Key(conv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.error.withOpacity(0.2),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => chatService.deleteConversation(conv.id),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatScreen(conversationId: conv.id, model: conv.model),
          ),
        ),
        onLongPress: () =>
            _showConvOptions(context, conv, chatService),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Model indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: modelColor.withOpacity(0.12),
                ),
                child: Icon(Icons.auto_awesome, size: 18, color: modelColor),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (conv.isPinned) ...[
                          Icon(Icons.push_pin,
                              size: 14,
                              color: AppColors.warning.withOpacity(0.8)),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            conv.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (conv.lastMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        conv.lastMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(conv.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: modelColor.withOpacity(0.12),
                    ),
                    child: Text(
                      conv.model.displayName.split(' ').first,
                      style: TextStyle(
                          fontSize: 10,
                          color: modelColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewChatButton(BuildContext context, ChatService chatService) {
    return GestureDetector(
      onTap: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        final conv = await chatService.createConversation(
          userId: user.uid,
          model: AIModel.claude,
          folderId: _selectedFolder,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatScreen(conversationId: conv.id, model: AIModel.claude),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AppColors.primaryGradient,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 56, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No conversations yet',
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Start chatting with AI!',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.2))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  void _showConvOptions(
      BuildContext context, ConversationModel conv, ChatService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 20),
            _optionTile(
              icon: conv.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              title: conv.isPinned ? 'Unpin' : 'Pin to Top',
              onTap: () {
                service.togglePin(conv.id, conv.isPinned);
                Navigator.pop(context);
              },
            ),
            _optionTile(
              icon: Icons.folder_outlined,
              title: 'Move to Folder',
              onTap: () {
                Navigator.pop(context);
                // Show folder picker
              },
            ),
            _optionTile(
              icon: Icons.share_outlined,
              title: 'Share Conversation',
              onTap: () async {
                final shareId = await service.shareConversation(conv.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share link: auraai.app/c/$shareId')),
                );
              },
            ),
            _optionTile(
              icon: Icons.edit_outlined,
              title: 'Rename',
              onTap: () {
                Navigator.pop(context);
                _showRename(context, conv, service);
              },
            ),
            _optionTile(
              icon: Icons.delete_outline,
              title: 'Delete',
              color: AppColors.error,
              onTap: () {
                service.deleteConversation(conv.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(title, style: TextStyle(color: color ?? Colors.white)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showRename(
      BuildContext context, ConversationModel conv, ChatService service) {
    final controller = TextEditingController(text: conv.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New title'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              service.updateConversation(
                  conv.id, {'title': controller.text.trim()});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolder(
      BuildContext context, ChatService service, String uid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                service.createFolder(
                    userId: uid, name: controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

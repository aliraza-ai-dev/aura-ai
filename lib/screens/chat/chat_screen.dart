import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/chat_service.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final AIModel model;
  final String? initialPrompt;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.model,
    this.initialPrompt,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  late AIModel _selectedModel;
  bool _isLoading = false;
  bool _showAttachMenu = false;
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.model;
    if (widget.initialPrompt != null) {
      _msgController.text = widget.initialPrompt!;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? overrideMsg]) async {
    final text = overrideMsg ?? _msgController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check daily limit
    final auth = context.read<AuthService>();
    final userData = await auth.getUserData(user.uid);
    if (userData != null && !userData.canSendMessage) {
      _showLimitDialog();
      return;
    }

    _msgController.clear();
    setState(() => _isLoading = true);

    final chatService = context.read<ChatService>();
    final aiService = context.read<AIService>();

    // Save user message
    await chatService.sendMessage(
      conversationId: widget.conversationId,
      content: text,
      isUser: true,
      model: _selectedModel,
    );

    _conversationHistory.add({'role': 'user', 'content': text});
    _scrollToBottom();

    // Increment usage
    await auth.incrementMessageCount(user.uid);

    try {
      // Get AI response
      final response = await aiService.sendMessage(
        model: _selectedModel,
        message: text,
        conversationHistory: _conversationHistory,
      );

      _conversationHistory.add({'role': 'assistant', 'content': response});

      // Save AI message
      await chatService.sendMessage(
        conversationId: widget.conversationId,
        content: response,
        isUser: false,
        model: _selectedModel,
      );
    } catch (e) {
      await chatService.sendMessage(
        conversationId: widget.conversationId,
        content: '⚠️ Error: ${e.toString()}',
        isUser: false,
        model: _selectedModel,
      );
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64 = base64Encode(bytes);

    setState(() => _isLoading = true);

    final chatService = context.read<ChatService>();
    final aiService = context.read<AIService>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await chatService.sendMessage(
      conversationId: widget.conversationId,
      content: '📷 Image uploaded for analysis',
      isUser: true,
      model: _selectedModel,
      type: MessageType.image,
    );

    try {
      final response = await aiService.sendMessage(
        model: _selectedModel,
        message: 'Describe and analyze this image in detail.',
        conversationHistory: _conversationHistory,
        imageBase64: base64,
      );

      await chatService.sendMessage(
        conversationId: widget.conversationId,
        content: response,
        isUser: false,
        model: _selectedModel,
      );
    } catch (e) {
      await chatService.sendMessage(
        conversationId: widget.conversationId,
        content: '⚠️ Image analysis failed: $e',
        isUser: false,
        model: _selectedModel,
      );
    }

    setState(() {
      _isLoading = false;
      _showAttachMenu = false;
    });
    _scrollToBottom();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    // For simplicity, read as text. For PDF, use pdf_text package
    String content = '';
    try {
      if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
    } catch (_) {
      content = '[Document content could not be read directly. Please paste the text.]';
    }

    setState(() => _isLoading = true);

    final chatService = context.read<ChatService>();
    final aiService = context.read<AIService>();

    await chatService.sendMessage(
      conversationId: widget.conversationId,
      content: '📄 Document uploaded: ${file.name}',
      isUser: true,
      model: _selectedModel,
      type: MessageType.document,
      documentName: file.name,
    );

    try {
      final response = await aiService.sendMessage(
        model: _selectedModel,
        message: 'Please summarize this document and highlight key points.',
        conversationHistory: _conversationHistory,
        documentText: content,
      );

      await chatService.sendMessage(
        conversationId: widget.conversationId,
        content: response,
        isUser: false,
        model: _selectedModel,
      );
    } catch (e) {
      await chatService.sendMessage(
        conversationId: widget.conversationId,
        content: '⚠️ Document analysis failed: $e',
        isUser: false,
        model: _selectedModel,
      );
    }

    setState(() {
      _isLoading = false;
      _showAttachMenu = false;
    });
    _scrollToBottom();
  }

  Future<void> _generateImage() async {
    final prompt = _msgController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an image description first')),
      );
      return;
    }

    _msgController.clear();
    setState(() => _isLoading = true);

    final chatService = context.read<ChatService>();
    final aiService = context.read<AIService>();

    await chatService.sendMessage(
      conversationId: widget.conversationId,
      content: '🎨 Generate image: $prompt',
      isUser: true,
      model: _selectedModel,
      type: MessageType.imageGeneration,
    );

    try {
      final imageUrl = await aiService.generateImage(prompt);
      await chatService.sendMessage(
        conversationId: widget.conversationId,
        content: 'Here is your generated image:',
        isUser: false,
        model: _selectedModel,
        type: MessageType.imageGeneration,
        imageUrl: imageUrl,
      );
    } catch (e) {
      await chatService.sendMessage(
        conversationId: widget.conversationId,
        content: '⚠️ Image generation failed: $e',
        isUser: false,
        model: _selectedModel,
      );
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Daily Limit Reached'),
        content: const Text(
          'You\'ve used all 10 free messages today.\nUpgrade to Pro for unlimited messages!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Color _modelColor(AIModel model) {
    switch (model) {
      case AIModel.claude:
        return AppColors.claudeColor;
      case AIModel.gpt4:
        return AppColors.gptColor;
      case AIModel.gemini:
        return AppColors.geminiColor;
      case AIModel.custom:
        return AppColors.customColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatService = context.read<ChatService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _modelColor(_selectedModel),
              ),
            ),
            const SizedBox(width: 8),
            Text(_selectedModel.displayName,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          // Model Switcher
          PopupMenuButton<AIModel>(
            icon: const Icon(Icons.swap_horiz, size: 22),
            color: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onSelected: (model) => setState(() => _selectedModel = model),
            itemBuilder: (_) => AIModel.values.map((m) {
              return PopupMenuItem(
                value: m,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _modelColor(m),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(m.displayName),
                    if (m == _selectedModel) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          // Share conversation
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () async {
              final shareId = await chatService.shareConversation(
                  widget.conversationId);
              Share.share(
                  'Check out this AuraAI conversation: https://auraai.app/chat/$shareId');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_isLoading && i == messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(messages[i], isDark);
                  },
                );
              },
            ),
          ),

          // Attach menu
          if (_showAttachMenu) _buildAttachMenu(isDark),

          // Input
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Icon(Icons.auto_awesome, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('Start a Conversation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Ask anything, upload images, or\ngenerate AI art',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isDark) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _modelColor(msg.model).withOpacity(0.15),
              ),
              child: Icon(Icons.auto_awesome,
                  size: 16, color: _modelColor(msg.model)),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  gradient: isUser ? AppColors.primaryGradient : null,
                  color: isUser
                      ? null
                      : (isDark ? AppColors.darkCard : AppColors.lightCardLight),
                  border: isUser
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 0.5,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image if present
                    if (msg.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          msg.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 200,
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Document badge
                    if (msg.type == MessageType.document &&
                        msg.documentName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.description, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(msg.documentName!,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Message content
                    if (isUser)
                      Text(
                        msg.content,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      )
                    else
                      MarkdownBody(
                        data: msg.content,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                          ),
                          code: TextStyle(
                            fontSize: 13,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.05),
                            color: AppColors.secondary,
                          ),
                          codeblockDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _modelColor(_selectedModel).withOpacity(0.15),
            ),
            child: Icon(Icons.auto_awesome,
                size: 16, color: _modelColor(_selectedModel)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.darkCard,
              border: Border.all(color: AppColors.darkBorder, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (i * 200)),
                  builder: (_, value, __) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _modelColor(_selectedModel)
                            .withOpacity(0.3 + (value * 0.5)),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachMenu(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _attachOption(Icons.image_rounded, 'Image', AppColors.accent, _pickImage),
          _attachOption(Icons.description_rounded, 'Document', AppColors.secondary, _pickDocument),
          _attachOption(Icons.palette_rounded, 'Generate', AppColors.warning, _generateImage),
          _attachOption(Icons.mic_rounded, 'Voice', AppColors.primary, () {
            // TODO: Implement speech-to-text
            setState(() => _showAttachMenu = false);
          }),
        ],
      ),
    );
  }

  Widget _attachOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withOpacity(0.12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attach button
          GestureDetector(
            onTap: () => setState(() => _showAttachMenu = !_showAttachMenu),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _showAttachMenu
                    ? AppColors.primary.withOpacity(0.15)
                    : (isDark ? AppColors.darkCard : AppColors.lightCardLight),
              ),
              child: Icon(
                _showAttachMenu ? Icons.close : Icons.add,
                color: _showAttachMenu
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.5),
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark ? AppColors.darkCard : AppColors.lightCardLight,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: TextField(
                controller: _msgController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message ${_selectedModel.displayName}...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.25)
                        : Colors.black26,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _isLoading ? null : AppColors.primaryGradient,
                color: _isLoading ? Colors.grey.withOpacity(0.2) : null,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isLoading ? Colors.grey : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ==================== CONVERSATIONS ====================
  Future<ConversationModel> createConversation({
    required String userId,
    required AIModel model,
    String? folderId,
  }) async {
    final id = _uuid.v4();
    final conv = ConversationModel(
      id: id,
      userId: userId,
      title: 'New Chat',
      model: model,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      folderId: folderId,
    );

    await _db.collection('conversations').doc(id).set(conv.toMap());
    return conv;
  }

  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _db
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ConversationModel.fromFirestore(d))
          .toList();
      list.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    });
  }

  Stream<List<ConversationModel>> getFolderConversations(
      String userId, String folderId) {
    return _db
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .where('folderId', isEqualTo: folderId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ConversationModel.fromFirestore(d))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Future<void> updateConversation(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _db.collection('conversations').doc(id).update(data);
  }

  Future<void> deleteConversation(String id) async {
    // Delete all messages first
    final msgs = await _db
        .collection('messages')
        .where('conversationId', isEqualTo: id)
        .get();
    for (final doc in msgs.docs) {
      await doc.reference.delete();
    }
    await _db.collection('conversations').doc(id).delete();
  }

  Future<void> togglePin(String id, bool isPinned) async {
    await _db.collection('conversations').doc(id).update({'isPinned': !isPinned});
  }

  Future<void> moveToFolder(String convId, String? folderId) async {
    await _db.collection('conversations').doc(convId).update({
      'folderId': folderId,
    });
  }

  Future<String> shareConversation(String convId) async {
    final shareId = _uuid.v4().substring(0, 8);
    await _db.collection('conversations').doc(convId).update({
      'isShared': true,
      'shareId': shareId,
    });
    // Copy to shared collection for public access
    final conv = await _db.collection('conversations').doc(convId).get();
    final msgs = await _db
        .collection('messages')
        .where('conversationId', isEqualTo: convId)
        .get();

    await _db.collection('sharedConversations').doc(shareId).set({
      ...conv.data()!,
      'messages': msgs.docs.map((d) => d.data()).toList(),
    });

    return shareId;
  }

  // ==================== MESSAGES ====================
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    required bool isUser,
    required AIModel model,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? documentUrl,
    String? documentName,
  }) async {
    final id = _uuid.v4();
    final msg = MessageModel(
      id: id,
      conversationId: conversationId,
      content: content,
      isUser: isUser,
      type: type,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
      documentUrl: documentUrl,
      documentName: documentName,
      model: model,
    );

    await _db.collection('messages').doc(id).set(msg.toMap());

    // Update conversation metadata
    final updateData = <String, dynamic>{
      'lastMessage': content.length > 100
          ? '${content.substring(0, 100)}...'
          : content,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'messageCount': FieldValue.increment(1),
    };

    // Auto-title from first user message
    if (isUser) {
      final existingMsgs = await _db
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('isUser', isEqualTo: true)
          .get();
      if (existingMsgs.docs.length <= 1) {
        updateData['title'] = content.length > 40
            ? '${content.substring(0, 40)}...'
            : content;
      }
    }

    await _db
        .collection('conversations')
        .doc(conversationId)
        .update(updateData);

    return msg;
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MessageModel.fromFirestore(d))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  // ==================== FOLDERS ====================
  Future<FolderModel> createFolder({
    required String userId,
    required String name,
    String? icon,
  }) async {
    final id = _uuid.v4();
    final folder = FolderModel(
      id: id,
      userId: userId,
      name: name,
      icon: icon ?? '📁',
      createdAt: DateTime.now(),
    );
    await _db.collection('folders').doc(id).set(folder.toMap());
    return folder;
  }

  Stream<List<FolderModel>> getUserFolders(String userId) {
    return _db
        .collection('folders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => FolderModel.fromFirestore(d))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<void> deleteFolder(String id) async {
    // Remove folder assignment from all conversations
    final convs = await _db
        .collection('conversations')
        .where('folderId', isEqualTo: id)
        .get();
    for (final doc in convs.docs) {
      await doc.reference.update({'folderId': null});
    }
    await _db.collection('folders').doc(id).delete();
  }

  // ==================== SEARCH ====================
  Future<List<ConversationModel>> searchConversations(
      String userId, String query) async {
    final snap = await _db
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .get();

    final q = query.toLowerCase();
    return snap.docs
        .map((d) => ConversationModel.fromFirestore(d))
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            (c.lastMessage?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ==================== PROMPT TEMPLATES ====================
  Stream<List<PromptTemplate>> getPromptTemplates() {
    return _db.collection('promptTemplates').snapshots().map((snap) {
      return snap.docs.map((d) => PromptTemplate.fromFirestore(d)).toList();
    });
  }

  Future<void> seedPromptTemplates() async {
    final templates = [
      PromptTemplate(id: 'pt1', title: 'Code Review', description: 'Get your code reviewed', prompt: 'Please review the following code for bugs, performance issues, and best practices:\n\n[PASTE CODE]', category: 'coding', icon: '💻'),
      PromptTemplate(id: 'pt2', title: 'Debug Helper', description: 'Fix errors in your code', prompt: 'I have this error in my code:\n\nError: [PASTE ERROR]\n\nCode:\n[PASTE CODE]\n\nPlease help me fix it.', category: 'coding', icon: '🐛'),
      PromptTemplate(id: 'pt3', title: 'Blog Post', description: 'Generate a blog post', prompt: 'Write a comprehensive blog post about [TOPIC]. Include an engaging introduction, 3-5 main sections, and a conclusion. Target audience: [AUDIENCE].', category: 'writing', icon: '✍️'),
      PromptTemplate(id: 'pt4', title: 'Email Draft', description: 'Compose professional emails', prompt: 'Write a professional email about [TOPIC] to [RECIPIENT]. Tone: [formal/casual/friendly]. Key points to cover:\n- [POINT 1]\n- [POINT 2]', category: 'writing', icon: '📧'),
      PromptTemplate(id: 'pt5', title: 'Social Media Post', description: 'Create viral social posts', prompt: 'Create a [PLATFORM] post about [TOPIC]. Include relevant hashtags, emojis, and a call-to-action. Make it engaging and shareable.', category: 'marketing', icon: '📱'),
      PromptTemplate(id: 'pt6', title: 'Ad Copy', description: 'Write compelling ads', prompt: 'Write ad copy for [PRODUCT/SERVICE]. Target audience: [AUDIENCE]. Key benefits: [LIST]. Include headline, body, and CTA.', category: 'marketing', icon: '📢'),
      PromptTemplate(id: 'pt7', title: 'Summarize Text', description: 'Get quick summaries', prompt: 'Summarize the following text in bullet points, highlighting the key takeaways:\n\n[PASTE TEXT]', category: 'productivity', icon: '📋'),
      PromptTemplate(id: 'pt8', title: 'Explain Like I\'m 5', description: 'Simple explanations', prompt: 'Explain [CONCEPT] in simple terms that a 5-year-old could understand. Use analogies and examples.', category: 'learning', icon: '🧒'),
      PromptTemplate(id: 'pt9', title: 'Image Prompt', description: 'Generate AI image prompts', prompt: 'Create a detailed image generation prompt for: [DESCRIPTION]. Include style, lighting, mood, and composition details.', category: 'creative', icon: '🎨', isPremium: true),
      PromptTemplate(id: 'pt10', title: 'Business Plan', description: 'Draft business plans', prompt: 'Create a business plan outline for [BUSINESS IDEA]. Include: Executive Summary, Market Analysis, Revenue Model, Marketing Strategy, and Financial Projections.', category: 'business', icon: '💼', isPremium: true),
    ];

    for (final t in templates) {
      await _db.collection('promptTemplates').doc(t.id).set(t.toMap());
    }
  }
}

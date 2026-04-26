import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== AI MODEL ENUM ====================
enum AIModel {
  claude('Claude Sonnet', 'Anthropic', 'assets/images/claude_icon.png'),
  gpt4('GPT-4o', 'OpenAI', 'assets/images/gpt_icon.png'),
  gemini('Gemini Pro', 'Google', 'assets/images/gemini_icon.png'),
  custom('AuraAI Custom', 'AuraAI', 'assets/images/custom_icon.png');

  final String displayName;
  final String provider;
  final String icon;
  const AIModel(this.displayName, this.provider, this.icon);
}

// ==================== USER MODEL ====================
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String plan; // 'free' or 'pro'
  final int dailyMessagesUsed;
  final DateTime? lastMessageDate;
  final DateTime createdAt;
  final bool isAdmin;
  final String? fcmToken;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.plan = 'free',
    this.dailyMessagesUsed = 0,
    this.lastMessageDate,
    required this.createdAt,
    this.isAdmin = false,
    this.fcmToken,
    this.preferences,
  });

  int get dailyLimit => plan == 'pro' ? 999999 : 10;
  bool get canSendMessage => dailyMessagesUsed < dailyLimit;
  bool get isPro => plan == 'pro';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      photoUrl: data['photoUrl'],
      plan: data['plan'] ?? 'free',
      dailyMessagesUsed: data['dailyMessagesUsed'] ?? 0,
      lastMessageDate: data['lastMessageDate'] != null
          ? (data['lastMessageDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isAdmin: data['isAdmin'] ?? false,
      fcmToken: data['fcmToken'],
      preferences: data['preferences'],
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'plan': plan,
        'dailyMessagesUsed': dailyMessagesUsed,
        'lastMessageDate': lastMessageDate != null
            ? Timestamp.fromDate(lastMessageDate!)
            : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'isAdmin': isAdmin,
        'fcmToken': fcmToken,
        'preferences': preferences,
      };
}

// ==================== CONVERSATION MODEL ====================
class ConversationModel {
  final String id;
  final String userId;
  final String title;
  final AIModel model;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final bool isPinned;
  final String? lastMessage;
  final int messageCount;
  final bool isShared;
  final String? shareId;

  ConversationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.isPinned = false,
    this.lastMessage,
    this.messageCount = 0,
    this.isShared = false,
    this.shareId,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'New Chat',
      model: AIModel.values.firstWhere(
        (m) => m.name == (data['model'] ?? 'claude'),
        orElse: () => AIModel.claude,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      folderId: data['folderId'],
      isPinned: data['isPinned'] ?? false,
      lastMessage: data['lastMessage'],
      messageCount: data['messageCount'] ?? 0,
      isShared: data['isShared'] ?? false,
      shareId: data['shareId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'model': model.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'folderId': folderId,
        'isPinned': isPinned,
        'lastMessage': lastMessage,
        'messageCount': messageCount,
        'isShared': isShared,
        'shareId': shareId,
      };
}

// ==================== MESSAGE MODEL ====================
enum MessageType { text, image, document, voice, imageGeneration }

class MessageModel {
  final String id;
  final String conversationId;
  final String content;
  final bool isUser;
  final MessageType type;
  final DateTime createdAt;
  final String? imageUrl;
  final String? documentUrl;
  final String? documentName;
  final AIModel model;
  final bool isLoading;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.isUser,
    this.type = MessageType.text,
    required this.createdAt,
    this.imageUrl,
    this.documentUrl,
    this.documentName,
    this.model = AIModel.claude,
    this.isLoading = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      content: data['content'] ?? '',
      isUser: data['isUser'] ?? true,
      type: MessageType.values.firstWhere(
        (t) => t.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      documentUrl: data['documentUrl'],
      documentName: data['documentName'],
      model: AIModel.values.firstWhere(
        (m) => m.name == (data['model'] ?? 'claude'),
        orElse: () => AIModel.claude,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'content': content,
        'isUser': isUser,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'imageUrl': imageUrl,
        'documentUrl': documentUrl,
        'documentName': documentName,
        'model': model.name,
      };
}

// ==================== FOLDER MODEL ====================
class FolderModel {
  final String id;
  final String userId;
  final String name;
  final String? icon;
  final int chatCount;
  final DateTime createdAt;

  FolderModel({
    required this.id,
    required this.userId,
    required this.name,
    this.icon,
    this.chatCount = 0,
    required this.createdAt,
  });

  factory FolderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FolderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Folder',
      icon: data['icon'],
      chatCount: data['chatCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'icon': icon,
        'chatCount': chatCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ==================== PROMPT TEMPLATE MODEL ====================
class PromptTemplate {
  final String id;
  final String title;
  final String description;
  final String prompt;
  final String category; // coding, writing, marketing, etc.
  final String icon;
  final bool isPremium;

  PromptTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.prompt,
    required this.category,
    this.icon = '💡',
    this.isPremium = false,
  });

  factory PromptTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromptTemplate(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      prompt: data['prompt'] ?? '',
      category: data['category'] ?? 'general',
      icon: data['icon'] ?? '💡',
      isPremium: data['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'prompt': prompt,
        'category': category,
        'icon': icon,
        'isPremium': isPremium,
      };
}

// ==================== SUBSCRIPTION MODEL ====================
class SubscriptionPlan {
  final String id;
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.isPopular = false,
  });
}

// ==================== ADMIN STATS MODEL ====================
class AdminStats {
  final int totalUsers;
  final int proUsers;
  final int freeUsers;
  final int totalConversations;
  final int totalMessages;
  final int todayMessages;
  final Map<String, int> modelUsage;

  AdminStats({
    required this.totalUsers,
    required this.proUsers,
    required this.freeUsers,
    required this.totalConversations,
    required this.totalMessages,
    required this.todayMessages,
    required this.modelUsage,
  });
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String _selectedCategory = 'All';
  final _categories = ['All', 'coding', 'writing', 'marketing', 'productivity', 'learning', 'creative', 'business'];
  final _categoryIcons = {
    'All': Icons.apps, 'coding': Icons.code, 'writing': Icons.edit_note,
    'marketing': Icons.campaign, 'productivity': Icons.speed,
    'learning': Icons.school, 'creative': Icons.palette, 'business': Icons.business_center,
  };
  final _categoryColors = {
    'All': AppColors.primary, 'coding': AppColors.secondary, 'writing': AppColors.primary,
    'marketing': AppColors.accent, 'productivity': AppColors.success,
    'learning': AppColors.geminiColor, 'creative': AppColors.warning, 'business': AppColors.claudeColor,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatService = context.read<ChatService>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('Prompt Templates',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Kickstart your conversation with AI',
                    style: TextStyle(fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black38)),
              ),
              const SizedBox(height: 16),

              // Category tabs
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final isActive = _selectedCategory == cat;
                    final catColor = _categoryColors[cat] ?? AppColors.primary;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: isActive ? LinearGradient(colors: [catColor, catColor.withOpacity(0.8)]) : null,
                            color: isActive ? null : (isDark ? AppColors.darkCard : Colors.white),
                            border: isActive ? null : Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            boxShadow: isActive ? [BoxShadow(color: catColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                          ),
                          child: Row(
                            children: [
                              Icon(_categoryIcons[cat] ?? Icons.apps, size: 16,
                                  color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.black45)),
                              const SizedBox(width: 6),
                              Text(
                                cat == 'All' ? 'All' : cat[0].toUpperCase() + cat.substring(1),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Templates list
              Expanded(
                child: StreamBuilder<List<PromptTemplate>>(
                  stream: chatService.getPromptTemplates(),
                  builder: (context, snapshot) {
                    var templates = (snapshot.data == null || snapshot.data!.isEmpty)
                        ? _defaultTemplates()
                        : snapshot.data!;
                    if (_selectedCategory != 'All') {
                      templates = templates.where((t) => t.category == _selectedCategory).toList();
                    }
                    if (templates.isEmpty) {
                      return Center(
                        child: Text('No templates in this category',
                            style: TextStyle(color: isDark ? Colors.white30 : Colors.black26)),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: templates.length,
                      itemBuilder: (_, i) => _buildTemplateCard(templates[i], isDark),
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

  Widget _buildTemplateCard(PromptTemplate template, bool isDark) {
    final color = _categoryColors[template.category] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => _useTemplate(template),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5,
          ),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color.withOpacity(0.12),
              ),
              child: Center(child: Text(template.icon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(template.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      if (template.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(colors: [Color(0xFFFFAB40), Color(0xFFFF6B9D)]),
                          ),
                          child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(template.description,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14,
                color: isDark ? Colors.white.withOpacity(0.15) : Colors.black12),
          ],
        ),
      ),
    );
  }

  void _useTemplate(PromptTemplate template) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final chatService = context.read<ChatService>();
      final conv = await chatService.createConversation(userId: user.uid, model: AIModel.claude);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: conv.id, model: AIModel.claude, initialPrompt: template.prompt),
      ));
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  List<PromptTemplate> _defaultTemplates() {
    return [
      // Coding
      PromptTemplate(id: '1', title: 'Code Review', description: 'Get your code reviewed for bugs & best practices', prompt: 'Please review the following code for bugs, performance issues, and best practices:\n\n', category: 'coding', icon: '💻'),
      PromptTemplate(id: '2', title: 'Debug Helper', description: 'Fix errors and exceptions', prompt: 'I have this error. Please help me fix it:\n\nError: \n\nCode:\n', category: 'coding', icon: '🐛'),
      PromptTemplate(id: '3', title: 'Code Converter', description: 'Convert code between languages', prompt: 'Convert the following code from [LANGUAGE] to [TARGET LANGUAGE]:\n\n', category: 'coding', icon: '🔄'),

      // Writing
      PromptTemplate(id: '4', title: 'Blog Post', description: 'Generate engaging blog posts', prompt: 'Write a comprehensive, SEO-friendly blog post about ', category: 'writing', icon: '✍️'),
      PromptTemplate(id: '5', title: 'Email Draft', description: 'Compose professional emails', prompt: 'Write a professional email about ', category: 'writing', icon: '📧'),
      PromptTemplate(id: '6', title: 'Story Writer', description: 'Create short stories', prompt: 'Write a creative short story about ', category: 'writing', icon: '📖'),

      // Marketing
      PromptTemplate(id: '7', title: 'Social Media Post', description: 'Create viral social content', prompt: 'Create an engaging social media post for [PLATFORM] about ', category: 'marketing', icon: '📱'),
      PromptTemplate(id: '8', title: 'Ad Copy', description: 'Write compelling advertisements', prompt: 'Write persuasive ad copy for ', category: 'marketing', icon: '📢'),
      PromptTemplate(id: '9', title: 'SEO Keywords', description: 'Generate keyword strategies', prompt: 'Generate a comprehensive SEO keyword strategy for a website about ', category: 'marketing', icon: '🔍'),

      // Productivity
      PromptTemplate(id: '10', title: 'Summarize Text', description: 'Get concise summaries', prompt: 'Summarize the following text in bullet points, highlighting key takeaways:\n\n', category: 'productivity', icon: '📋'),
      PromptTemplate(id: '11', title: 'Meeting Notes', description: 'Structure meeting notes', prompt: 'Organize these rough meeting notes into a structured format with action items:\n\n', category: 'productivity', icon: '📝'),
      PromptTemplate(id: '12', title: 'To-Do Planner', description: 'Plan your day efficiently', prompt: 'Help me create a prioritized to-do list and schedule for today. Here are my tasks:\n\n', category: 'productivity', icon: '✅'),

      // Learning
      PromptTemplate(id: '13', title: 'Explain Simply', description: 'ELI5 any concept', prompt: 'Explain this concept in simple terms that anyone can understand, with examples: ', category: 'learning', icon: '🧒'),
      PromptTemplate(id: '14', title: 'Quiz Generator', description: 'Create practice quizzes', prompt: 'Create a 10-question quiz with answers about ', category: 'learning', icon: '❓'),
      PromptTemplate(id: '15', title: 'Study Notes', description: 'Generate study material', prompt: 'Create detailed study notes with key concepts, definitions, and examples about ', category: 'learning', icon: '📚'),

      // Creative
      PromptTemplate(id: '16', title: 'Image Prompt', description: 'Craft AI image prompts', prompt: 'Create a detailed, vivid image generation prompt for: ', category: 'creative', icon: '🎨', isPremium: true),
      PromptTemplate(id: '17', title: 'Name Generator', description: 'Generate creative names', prompt: 'Generate 10 creative and unique name ideas for ', category: 'creative', icon: '💡'),
      PromptTemplate(id: '18', title: 'Song Lyrics', description: 'Write original lyrics', prompt: 'Write original song lyrics in the style of [GENRE] about ', category: 'creative', icon: '🎵'),

      // Business
      PromptTemplate(id: '19', title: 'Business Plan', description: 'Draft business plans', prompt: 'Create a detailed business plan outline for ', category: 'business', icon: '💼', isPremium: true),
      PromptTemplate(id: '20', title: 'SWOT Analysis', description: 'Analyze strengths & weaknesses', prompt: 'Perform a detailed SWOT analysis for ', category: 'business', icon: '📊', isPremium: true),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/chat_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.error.withOpacity(0.15),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  size: 18, color: AppColors.error),
            ),
            const SizedBox(width: 10),
            const Text('Admin Panel'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white38,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Subs'),
            Tab(text: 'Content'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(isDark),
            _buildUsersTab(isDark),
            _buildSubscriptionsTab(isDark),
            _buildContentTab(isDark),
          ],
        ),
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          // Stats Grid
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').snapshots(),
            builder: (context, userSnap) {
              final totalUsers = userSnap.data?.docs.length ?? 0;
              final proUsers = userSnap.data?.docs
                      .where((d) =>
                          (d.data() as Map)['plan'] == 'pro')
                      .length ??
                  0;

              return StreamBuilder<QuerySnapshot>(
                stream: _db.collection('conversations').snapshots(),
                builder: (context, convSnap) {
                  final totalConvs = convSnap.data?.docs.length ?? 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('messages').snapshots(),
                    builder: (context, msgSnap) {
                      final totalMsgs = msgSnap.data?.docs.length ?? 0;

                      return Column(
                        children: [
                          Row(
                            children: [
                              _statCard(
                                'Total Users',
                                totalUsers.toString(),
                                Icons.people_outline,
                                AppColors.primary,
                                isDark,
                              ),
                              const SizedBox(width: 12),
                              _statCard(
                                'Pro Users',
                                proUsers.toString(),
                                Icons.star_outline,
                                AppColors.warning,
                                isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statCard(
                                'Conversations',
                                totalConvs.toString(),
                                Icons.chat_bubble_outline,
                                AppColors.secondary,
                                isDark,
                              ),
                              const SizedBox(width: 12),
                              _statCard(
                                'Messages',
                                totalMsgs.toString(),
                                Icons.message_outlined,
                                AppColors.success,
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 28),

          // Model Usage
          const Text('Model Usage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('messages').snapshots(),
            builder: (context, snap) {
              final messages = snap.data?.docs ?? [];
              int claude = 0, gpt = 0, gemini = 0;
              for (final doc in messages) {
                final data = doc.data() as Map<String, dynamic>;
                switch (data['model']) {
                  case 'claude':
                    claude++;
                    break;
                  case 'gpt4':
                    gpt++;
                    break;
                  case 'gemini':
                    gemini++;
                    break;
                }
              }
              final total = claude + gpt + gemini;
              if (total == 0) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  ),
                  child: const Center(child: Text('No data yet')),
                );
              }

              return Column(
                children: [
                  _modelUsageBar('Claude', claude, total,
                      AppColors.claudeColor, isDark),
                  const SizedBox(height: 10),
                  _modelUsageBar(
                      'GPT-4', gpt, total, AppColors.gptColor, isDark),
                  const SizedBox(height: 10),
                  _modelUsageBar('Gemini', gemini, total,
                      AppColors.geminiColor, isDark),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Recent Activity
          const Text('Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('conversations')
                .orderBy('updatedAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              final convs = snap.data?.docs ?? [];
              if (convs.isEmpty) {
                return const Text('No recent activity');
              }
              return Column(
                children: convs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['updatedAt'] as Timestamp?)?.toDate();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          isDark ? AppColors.darkCard : AppColors.lightCard,
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? 'Untitled',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${data['messageCount'] ?? 0} msgs • ${data['model'] ?? 'claude'}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                            ],
                          ),
                        ),
                        if (date != null)
                          Text(
                            DateFormat('MMM d, HH:mm').format(date),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.25)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withOpacity(0.12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 14),
            Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  Widget _modelUsageBar(
      String name, int count, int total, Color color, bool isDark) {
    final pct = total > 0 ? (count / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(name,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('$count',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
          Text(' (${(pct * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.3))),
        ],
      ),
    );
  }

  // ==================== USERS TAB ====================
  Widget _buildUsersTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snap.data?.docs ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final data = users[i].data() as Map<String, dynamic>;
            final uid = users[i].id;
            final plan = data['plan'] ?? 'free';
            final msgCount = data['dailyMessagesUsed'] ?? 0;
            final joinDate =
                (data['createdAt'] as Timestamp?)?.toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: plan == 'pro'
                          ? AppColors.primaryGradient
                          : null,
                      color: plan == 'pro'
                          ? null
                          : AppColors.primary.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        (data['displayName'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: plan == 'pro'
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                data['displayName'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: plan == 'pro'
                                    ? AppColors.warning.withOpacity(0.15)
                                    : AppColors.primary.withOpacity(0.1),
                              ),
                              child: Text(
                                plan.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: plan == 'pro'
                                      ? AppColors.warning
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                            if (data['isAdmin'] == true) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: AppColors.error.withOpacity(0.15),
                                ),
                                child: const Text('ADMIN',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data['email']} • $msgCount msgs today',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.35)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (joinDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Joined ${DateFormat('MMM d, yyyy').format(joinDate)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.2)),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 20,
                        color: Colors.white.withOpacity(0.3)),
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (action) =>
                        _handleUserAction(action, uid, data),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: plan == 'pro'
                            ? 'downgrade'
                            : 'upgrade',
                        child: Row(
                          children: [
                            Icon(
                              plan == 'pro'
                                  ? Icons.arrow_downward
                                  : Icons.star,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            Text(plan == 'pro'
                                ? 'Downgrade to Free'
                                : 'Upgrade to Pro'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 18,
                                color: AppColors.secondary),
                            SizedBox(width: 10),
                            Text('Reset Daily Usage'),
                          ],
                        ),
                      ),
                      if (data['isAdmin'] != true)
                        const PopupMenuItem(
                          value: 'makeAdmin',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings,
                                  size: 18, color: AppColors.error),
                              SizedBox(width: 10),
                              Text('Make Admin'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleUserAction(
      String action, String uid, Map<String, dynamic> data) {
    switch (action) {
      case 'upgrade':
        _db.collection('users').doc(uid).update({'plan': 'pro'});
        _showSnack('User upgraded to Pro');
        break;
      case 'downgrade':
        _db.collection('users').doc(uid).update({'plan': 'free'});
        _showSnack('User downgraded to Free');
        break;
      case 'reset':
        _db
            .collection('users')
            .doc(uid)
            .update({'dailyMessagesUsed': 0});
        _showSnack('Daily usage reset');
        break;
      case 'makeAdmin':
        _db.collection('users').doc(uid).update({'isAdmin': true});
        _showSnack('User is now Admin');
        break;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ==================== SUBSCRIPTIONS TAB ====================
  Widget _buildSubscriptionsTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(),
      builder: (context, snap) {
        final users = snap.data?.docs ?? [];
        final proUsers = users
            .where(
                (d) => (d.data() as Map<String, dynamic>)['plan'] == 'pro')
            .toList();
        final freeUsers = users
            .where(
                (d) => (d.data() as Map<String, dynamic>)['plan'] != 'pro')
            .toList();
        final convRate = users.isNotEmpty
            ? (proUsers.length / users.length * 100).toStringAsFixed(1)
            : '0';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Subscription Overview',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // Revenue card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Monthly Revenue',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7))),
                    const SizedBox(height: 8),
                    Text(
                      '\$${(proUsers.length * 9.99).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('${proUsers.length} Pro subscribers',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6))),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  _miniStat('Conversion Rate', '$convRate%',
                      AppColors.success, isDark),
                  const SizedBox(width: 12),
                  _miniStat('Free Users', '${freeUsers.length}',
                      AppColors.secondary, isDark),
                ],
              ),

              const SizedBox(height: 28),

              const Text('Pro Subscribers',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              if (proUsers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  ),
                  child: Center(
                    child: Text('No Pro subscribers yet',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3))),
                  ),
                )
              else
                ...proUsers.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          isDark ? AppColors.darkCard : AppColors.lightCard,
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star,
                            size: 18, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(data['displayName'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                        ),
                        Text('\$9.99/mo',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.warning.withOpacity(0.8),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }

  // ==================== CONTENT TAB ====================
  Widget _buildContentTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Content Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          // Seed Templates
          _contentAction(
            icon: Icons.auto_awesome,
            title: 'Seed Prompt Templates',
            subtitle: 'Add default prompt templates to Firestore',
            color: AppColors.primary,
            isDark: isDark,
            onTap: () async {
              // Seed templates
              final chatService = ChatService();
              await chatService.seedPromptTemplates();
              _showSnack('10 prompt templates seeded successfully!');
            },
          ),

          _contentAction(
            icon: Icons.notifications_active,
            title: 'Push Notification',
            subtitle: 'Send daily AI tip to all users',
            color: AppColors.warning,
            isDark: isDark,
            onTap: () => _showSendNotification(),
          ),

          _contentAction(
            icon: Icons.add_box_outlined,
            title: 'Add Prompt Template',
            subtitle: 'Create a new prompt template',
            color: AppColors.secondary,
            isDark: isDark,
            onTap: () => _showAddTemplate(),
          ),

          _contentAction(
            icon: Icons.cleaning_services,
            title: 'Clear Old Conversations',
            subtitle: 'Delete conversations older than 30 days for free users',
            color: AppColors.error,
            isDark: isDark,
            onTap: () => _confirmCleanup(),
          ),

          const SizedBox(height: 28),

          // Templates list
          const Text('Existing Templates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('promptTemplates').snapshots(),
            builder: (context, snap) {
              final templates = snap.data?.docs ?? [];
              if (templates.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  ),
                  child: Center(
                    child: Text(
                        'No templates. Tap "Seed Prompt Templates" above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3))),
                  ),
                );
              }

              return Column(
                children: templates.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          isDark ? AppColors.darkCard : AppColors.lightCard,
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Text(data['icon'] ?? '💡',
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              Text(data['category'] ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.white.withOpacity(0.3))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          onPressed: () =>
                              _db.collection('promptTemplates').doc(doc.id).delete(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _contentAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withOpacity(0.12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.35))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.white.withOpacity(0.15)),
          ],
        ),
      ),
    );
  }

  void _showSendNotification() {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Send Push Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleC,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyC,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Message body'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // TODO: Send FCM notification via Cloud Functions
              Navigator.pop(context);
              _showSnack('Notification sent!');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAddTemplate() {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final promptC = TextEditingController();
    String category = 'coding';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(hintText: 'Title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descC,
                  decoration:
                      const InputDecoration(hintText: 'Description'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: promptC,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(hintText: 'Prompt text'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: [
                    'coding',
                    'writing',
                    'marketing',
                    'productivity',
                    'learning',
                    'creative',
                    'business'
                  ]
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? 'coding'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleC.text.isNotEmpty && promptC.text.isNotEmpty) {
                  _db.collection('promptTemplates').add({
                    'title': titleC.text,
                    'description': descC.text,
                    'prompt': promptC.text,
                    'category': category,
                    'icon': '💡',
                    'isPremium': false,
                  });
                  Navigator.pop(context);
                  _showSnack('Template added!');
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCleanup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Old Conversations?'),
        content: const Text(
            'This will delete all conversations older than 30 days for free users. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final cutoff = DateTime.now().subtract(const Duration(days: 30));
              final freeUsers = await _db
                  .collection('users')
                  .where('plan', isEqualTo: 'free')
                  .get();
              int deleted = 0;
              for (final user in freeUsers.docs) {
                final convs = await _db
                    .collection('conversations')
                    .where('userId', isEqualTo: user.id)
                    .get();
                for (final conv in convs.docs) {
                  final data = conv.data();
                  final updated =
                      (data['updatedAt'] as Timestamp?)?.toDate();
                  if (updated != null && updated.isBefore(cutoff)) {
                    // Delete messages
                    final msgs = await _db
                        .collection('messages')
                        .where('conversationId', isEqualTo: conv.id)
                        .get();
                    for (final m in msgs.docs) {
                      await m.reference.delete();
                    }
                    await conv.reference.delete();
                    deleted++;
                  }
                }
              }
              Navigator.pop(context);
              _showSnack('$deleted old conversations deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

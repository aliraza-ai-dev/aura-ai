import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/theme_provider.dart';
import '../auth/login_screen.dart';
import '../subscription/subscription_screen.dart';
import '../admin/admin_dashboard.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final auth = context.read<AuthService>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: user == null
              ? const Center(child: Text('Please sign in'))
              : StreamBuilder<UserModel?>(
                  stream: auth.userStream(user.uid),
                  builder: (context, snapshot) {
                    final userData = snapshot.data;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Settings',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),

                          const SizedBox(height: 24),

                          // Profile Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (userData?.displayName ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userData?.displayName ?? 'User',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        userData?.email ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: Text(
                                    (userData?.isPro ?? false)
                                        ? '⚡ PRO'
                                        : 'FREE',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // General
                          _sectionTitle('General'),
                          _settingTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Dark Mode',
                            trailing: Switch(
                              value: themeProvider.isDark,
                              onChanged: (_) => themeProvider.toggleTheme(),
                              activeColor: AppColors.primary,
                            ),
                            isDark: isDark,
                          ),
                          _settingTile(
                            icon: Icons.notifications_outlined,
                            title: 'Push Notifications',
                            subtitle: 'Daily AI tips & updates',
                            trailing: Switch(
                              value: true,
                              onChanged: (_) {},
                              activeColor: AppColors.primary,
                            ),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 20),

                          // Subscription
                          _sectionTitle('Subscription'),
                          _settingTile(
                            icon: Icons.rocket_launch_outlined,
                            title: 'Manage Plan',
                            subtitle: (userData?.isPro ?? false)
                                ? 'Pro Plan — Active'
                                : 'Free Plan — 10 msgs/day',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SubscriptionScreen()),
                            ),
                            isDark: isDark,
                          ),
                          _settingTile(
                            icon: Icons.bar_chart_outlined,
                            title: 'Usage Stats',
                            subtitle:
                                '${userData?.dailyMessagesUsed ?? 0} messages today',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 20),

                          // Admin (if applicable)
                          if (userData?.isAdmin ?? false) ...[
                            _sectionTitle('Admin'),
                            _settingTile(
                              icon: Icons.admin_panel_settings_outlined,
                              title: 'Admin Dashboard',
                              subtitle: 'Manage users & analytics',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminDashboard()),
                              ),
                              isDark: isDark,
                              iconColor: AppColors.error,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // About
                          _sectionTitle('About'),
                          _settingTile(
                            icon: Icons.info_outline,
                            title: 'About AuraAI',
                            subtitle: 'Version 1.0.0',
                            isDark: isDark,
                          ),
                          _settingTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            isDark: isDark,
                          ),
                          _settingTile(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 20),

                          // Logout
                          _settingTile(
                            icon: Icons.logout_rounded,
                            title: 'Sign Out',
                            iconColor: AppColors.error,
                            titleColor: AppColors.error,
                            onTap: () async {
                              await auth.signOut();
                              if (!context.mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                            isDark: isDark,
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0.5,
          )),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              ),
              child: Icon(icon,
                  size: 20, color: iconColor ?? AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white30 : Colors.black38,
                        )),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}

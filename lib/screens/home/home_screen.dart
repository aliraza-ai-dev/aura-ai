import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';
import '../subscription/subscription_screen.dart';
import '../admin/admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _contentController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _contentController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final auth = context.read<AuthService>();

    return Scaffold(
      body: Stack(
        children: [
          // ===== ANIMATED BACKGROUND =====
          _buildAnimatedBg(isDark),

          // ===== MAIN CONTENT =====
          SafeArea(
            child: user == null
                ? const Center(child: Text('Please sign in'))
                : StreamBuilder<UserModel?>(
                    stream: auth.userStream(user.uid),
                    builder: (context, snapshot) {
                      final userData = snapshot.data;
                      return FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(context, userData, isDark),
                                const SizedBox(height: 18),
                                _buildHeroBanner(isDark),
                                const SizedBox(height: 14),
                                _buildUsageCard(userData, isDark),
                                const SizedBox(height: 26),
                                _buildSectionTitle('Start a New Chat', isDark),
                                const SizedBox(height: 14),
                                _buildModelCards(context, isDark),
                                const SizedBox(height: 26),
                                _buildSectionTitle('Quick Actions', isDark),
                                const SizedBox(height: 14),
                                _buildQuickActions(context, isDark),
                                const SizedBox(height: 26),
                                if (!(userData?.isPro ?? false)) ...[
                                  _buildProBanner(context),
                                  const SizedBox(height: 22),
                                ],
                                _buildDailyTip(isDark),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ===== ANIMATED BACKGROUND WITH FLOATING ORBS =====
  Widget _buildAnimatedBg(bool isDark) {
    if (!isDark) {
      return Container(color: AppColors.lightBg);
    }
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        final t = _bgController.value;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF060A14), Color(0xFF0A0E1A), Color(0xFF10082A)],
            ),
          ),
          child: Stack(
            children: [
              // Floating orb 1 — purple
              Positioned(
                top: 80 + (math.sin(t * math.pi * 2) * 30),
                right: -40 + (math.cos(t * math.pi * 2) * 20),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.12),
                        AppColors.primary.withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Floating orb 2 — cyan
              Positioned(
                bottom: 200 + (math.cos(t * math.pi * 2) * 25),
                left: -60 + (math.sin(t * math.pi * 2) * 15),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.08),
                        AppColors.secondary.withOpacity(0.01),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Floating orb 3 — pink
              Positioned(
                top: 400 + (math.sin(t * math.pi * 1.5) * 20),
                right: 40 + (math.cos(t * math.pi * 1.5) * 25),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== GLASSMORPHISM HELPER =====
  Widget _glassCard({
    required Widget child,
    required bool isDark,
    EdgeInsets? padding,
    double borderRadius = 20,
    Color? borderColor,
    List<BoxShadow>? shadows,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: isDark ? 12 : 0, sigmaY: isDark ? 12 : 0),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.9),
            border: Border.all(
              color: borderColor ?? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
              width: 0.8,
            ),
            boxShadow: shadows ??
                (isDark
                    ? null
                    : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))]),
          ),
          child: child,
        ),
      ),
    );
  }

  // ===== HERO BANNER — Custom Designed =====
  Widget _buildHeroBanner(bool isDark) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        final t = _bgController.value;
        return Container(
          height: 175,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A3E), Color(0xFF3D1D8E), Color(0xFF2A1B6B)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Grid lines bg
                CustomPaint(
                  size: const Size(double.infinity, 175),
                  painter: _GridPainter(),
                ),

                // Floating glow orb 1
                Positioned(
                  top: -20 + (math.sin(t * math.pi * 2) * 8),
                  right: 20 + (math.cos(t * math.pi * 2) * 10),
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF00D4FF).withOpacity(0.25),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

                // Floating glow orb 2
                Positioned(
                  bottom: -15 + (math.cos(t * math.pi * 1.5) * 10),
                  left: 30 + (math.sin(t * math.pi * 1.5) * 8),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFFE040FB).withOpacity(0.2),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + Title Row
                      Row(
                        children: [
                          // Logo
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 12),
                              ],
                            ),
                            child: const Center(
                              child: Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AURA AI',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2)),
                              Text('Your Universal AI Assistant',
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), letterSpacing: 0.5)),
                            ],
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Model chips row
                      Row(
                        children: [
                          _bannerChip('Claude', AppColors.claudeColor),
                          const SizedBox(width: 8),
                          _bannerChip('GPT-4o', AppColors.gptColor),
                          const SizedBox(width: 8),
                          _bannerChip('Gemini', AppColors.geminiColor),
                          const SizedBox(width: 8),
                          _bannerChip('Custom', AppColors.customColor),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Tagline
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('4 AI Models', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withOpacity(0.08),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_rounded, size: 12, color: Colors.white.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text('AI Images', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withOpacity(0.08),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt, size: 12, color: Colors.white.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text('Fast', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Decorative corner dots
                Positioned(
                  top: 14, right: 16,
                  child: Row(
                    children: [
                      _dot(const Color(0xFFFF5252)),
                      const SizedBox(width: 5),
                      _dot(const Color(0xFFFFAB40)),
                      const SizedBox(width: 5),
                      _dot(const Color(0xFF00E676)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bannerChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildSectionTitle(String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: AppColors.primaryGradient,
          ),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            )),
      ],
    );
  }

  // ===== HEADER =====
  Widget _buildHeader(BuildContext context, UserModel? userData, bool isDark) {
    return Row(
      children: [
        // Glowing avatar
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark ? const Color(0xFF0A0E1A) : Colors.white,
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                child: Text(
                  (userData?.displayName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, ${userData?.displayName ?? 'there'} 👋',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: (userData?.isPro ?? false)
                      ? const LinearGradient(colors: [Color(0xFFFFAB40), Color(0xFFFF6B9D)])
                      : null,
                  color: (userData?.isPro ?? false) ? null : AppColors.primary.withOpacity(0.1),
                ),
                child: Text(
                  (userData?.isPro ?? false) ? '⚡ PRO' : '🆓 FREE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: (userData?.isPro ?? false) ? Colors.white : AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        if (userData?.isAdmin ?? false)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
            child: _glassCard(
              isDark: isDark,
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              borderColor: AppColors.error.withOpacity(0.2),
              child: const Icon(Icons.admin_panel_settings, color: AppColors.error, size: 20),
            ),
          ),
      ],
    );
  }

  // ===== USAGE CARD =====
  Widget _buildUsageCard(UserModel? user, bool isDark) {
    final used = user?.dailyMessagesUsed ?? 0;
    final limit = user?.dailyLimit ?? 10;
    final progress = user?.isPro == true ? 0.0 : (used / limit).clamp(0.0, 1.0);

    return _glassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: AppColors.primary.withOpacity(isDark ? 0.1 : 0.05),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text('Daily Usage',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF4A5568))),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: (user?.isPro == true ? AppColors.warning : (used >= limit ? AppColors.error : AppColors.secondary)).withOpacity(0.12),
                ),
                child: Text(
                  user?.isPro == true ? '∞ Unlimited' : '$used / $limit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: user?.isPro == true ? AppColors.warning : (used >= limit ? AppColors.error : AppColors.secondary)),
                ),
              ),
            ],
          ),
          if (user?.isPro != true) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: progress >= 0.8
                          ? const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFFF1744)])
                          : AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (progress >= 0.8 ? AppColors.error : AppColors.primary).withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                used >= limit ? '⚠️ Limit reached. Upgrade to Pro!' : '${limit - used} messages remaining',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== MODEL CARDS =====
  Widget _buildModelCards(BuildContext context, bool isDark) {
    final models = [
      _ModelData(AIModel.claude, AppColors.claudeColor, Icons.auto_awesome),
      _ModelData(AIModel.gpt4, AppColors.gptColor, Icons.psychology),
      _ModelData(AIModel.gemini, AppColors.geminiColor, Icons.diamond_outlined),
      _ModelData(AIModel.custom, AppColors.customColor, Icons.rocket_launch_rounded),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _modelCard(models[0], isDark, context)),
            const SizedBox(width: 10),
            Expanded(child: _modelCard(models[1], isDark, context)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _modelCard(models[2], isDark, context)),
            const SizedBox(width: 10),
            Expanded(child: _modelCard(models[3], isDark, context)),
          ],
        ),
      ],
    );
  }

  Widget _modelCard(_ModelData m, bool isDark, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _startChat(context, m.model),
        child: _glassCard(
          isDark: isDark,
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          borderColor: m.color.withOpacity(0.2),
          shadows: [BoxShadow(color: m.color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [m.color.withOpacity(0.2), m.color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: m.color.withOpacity(0.15), blurRadius: 10)],
                ),
                child: Icon(m.icon, color: m.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(m.model == AIModel.custom ? 'Custom' : m.model.displayName.split(' ').first,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: m.color)),
              const SizedBox(height: 2),
              Text(m.model.provider,
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black26)),
            ],
          ),
        ),
      ),
    );
  }

  // ===== QUICK ACTIONS — FIXED OVERFLOW =====
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      _ActionData(Icons.image_rounded, 'Generate Image', const Color(0xFFFF6B9D), const Color(0xFFFF8E53), AIModel.gpt4, 'Generate an image of: '),
      _ActionData(Icons.description_rounded, 'Summarize Doc', const Color(0xFF00D4FF), const Color(0xFF00E676), AIModel.claude, null),
      _ActionData(Icons.mic_rounded, 'Voice Chat', const Color(0xFF6C63FF), const Color(0xFF8B83FF), AIModel.claude, null),
      _ActionData(Icons.code_rounded, 'Code Helper', const Color(0xFFFFAB40), const Color(0xFFFF6B9D), AIModel.claude, 'Help me with this code:\n\n'),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _actionCard(actions[0], isDark, context)),
            const SizedBox(width: 12),
            Expanded(child: _actionCard(actions[1], isDark, context)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _actionCard(actions[2], isDark, context)),
            const SizedBox(width: 12),
            Expanded(child: _actionCard(actions[3], isDark, context)),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(_ActionData a, bool isDark, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _startChat(context, a.model, a.prompt),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: isDark ? 8 : 0, sigmaY: isDark ? 8 : 0),
            child: Container(
              height: 90,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    a.c1.withOpacity(isDark ? 0.12 : 0.06),
                    a.c2.withOpacity(isDark ? 0.04 : 0.01),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: a.c1.withOpacity(isDark ? 0.15 : 0.1), width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [a.c1.withOpacity(0.2), a.c2.withOpacity(0.1)],
                      ),
                    ),
                    child: Icon(a.icon, color: a.c1, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(a.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E),
                        )),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12,
                      color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== PRO BANNER =====
  Widget _buildProBanner(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4A3AFF), Color(0xFF00D4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 28, offset: const Offset(0, 12)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Upgrade to Pro',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Unlimited messages • All AI models\nImage generation • Priority support',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), height: 1.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                ),
                child: const Text('Go Pro',
                    style: TextStyle(color: Color(0xFF4A3AFF), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== DAILY TIP =====
  Widget _buildDailyTip(bool isDark) {
    final tips = [
      '💡 Tap any AI model card to start chatting instantly!',
      '💡 Long press a conversation to pin it to the top.',
      '💡 Upload a PDF and ask AI to summarize it.',
      '💡 Switch between Claude, GPT-4, Gemini mid-chat.',
      '💡 Use prompt templates for quick starters.',
    ];

    return _glassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.warning.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [AppColors.warning.withOpacity(0.15), AppColors.warning.withOpacity(0.05)]),
            ),
            child: const Icon(Icons.tips_and_updates_rounded, color: AppColors.warning, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(tips[DateTime.now().day % tips.length],
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF4A5568), height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ===== START CHAT =====
  void _startChat(BuildContext context, AIModel model, [String? initialPrompt]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2236),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20)],
          ),
          child: const SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          ),
        ),
      ),
    );

    try {
      final chatService = context.read<ChatService>();
      final conv = await chatService.createConversation(userId: user.uid, model: model);
      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: conv.id, model: model, initialPrompt: initialPrompt),
      ));
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// Data classes
class _ModelData {
  final AIModel model;
  final Color color;
  final IconData icon;
  _ModelData(this.model, this.color, this.icon);
}

class _ActionData {
  final IconData icon;
  final String title;
  final Color c1;
  final Color c2;
  final AIModel model;
  final String? prompt;
  _ActionData(this.icon, this.title, this.c1, this.c2, this.model, this.prompt);
}

// Grid line painter for banner background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 25.0;

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Diagonal accent line
    final accentPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xFF6C63FF), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

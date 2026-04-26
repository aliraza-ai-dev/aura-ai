import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPage(
      icon: Icons.auto_awesome,
      iconGradient: AppColors.primaryGradient,
      title: 'Multi-Model AI',
      subtitle: 'Chat with Claude, GPT-4, and Gemini.\nSwitch models mid-conversation.',
      bgGlow: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.image_rounded,
      iconGradient: AppColors.accentGradient,
      title: 'Generate Images',
      subtitle: 'Create stunning AI images with\nDALL-E 3 right in your chat.',
      bgGlow: AppColors.accent,
    ),
    _OnboardingPage(
      icon: Icons.description_rounded,
      iconGradient: const LinearGradient(
        colors: [Color(0xFF00D4FF), Color(0xFF00E676)],
      ),
      title: 'Analyze Documents',
      subtitle: 'Upload PDFs, images, and documents.\nAI summarizes instantly.',
      bgGlow: AppColors.secondary,
    ),
    _OnboardingPage(
      icon: Icons.rocket_launch_rounded,
      iconGradient: const LinearGradient(
        colors: [Color(0xFFFFAB40), Color(0xFFFF6B9D)],
      ),
      title: 'Ready to Start?',
      subtitle: 'Get 10 free messages daily.\nUpgrade to Pro for unlimited access.',
      bgGlow: AppColors.warning,
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: i == _currentPage
                          ? AppColors.primaryGradient
                          : null,
                      color: i == _currentPage
                          ? null
                          : Colors.white.withOpacity(0.2),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              // Next / Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      page.bgGlow.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: page.iconGradient,
                  boxShadow: [
                    BoxShadow(
                      color: page.bgGlow.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(page.icon, size: 56, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 48),

          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final LinearGradient iconGradient;
  final String title;
  final String subtitle;
  final Color bgGlow;

  _OnboardingPage({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.bgGlow,
  });
}

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlan = 1;

  final _plans = [
    SubscriptionPlan(
      id: 'free', name: 'Free', price: '\$0', period: 'forever',
      features: ['10 messages per day', 'Claude & GPT-4 access', 'Basic prompt templates', 'Chat history (7 days)', 'Light & Dark theme'],
    ),
    SubscriptionPlan(
      id: 'pro_monthly', name: 'Pro', price: '\$9.99', period: '/month', isPopular: true,
      features: ['Unlimited messages', 'All AI models', 'Image generation (DALL-E 3)', 'Document analysis', 'Voice input', 'All prompt templates', 'Unlimited chat history', 'Chat folders & pins', 'Share conversations', 'Priority support'],
    ),
    SubscriptionPlan(
      id: 'pro_yearly', name: 'Pro Annual', price: '\$79.99', period: '/year',
      features: ['Everything in Pro', 'Save 33% vs monthly', 'Early access to features', 'Custom prompt templates', 'API access (coming soon)'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A0E1A), Color(0xFF1A1040)])
              : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 20)),
                      Expanded(child: Text('Choose Your Plan', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                ShaderMask(
                  shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                  child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text('Unlock Full Power',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const SizedBox(height: 6),
                Text('Choose the plan that fits your needs',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),

                const SizedBox(height: 28),

                // Plans
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: List.generate(_plans.length, (i) => _buildPlanCard(_plans[i], i, isDark))),
                ),

                const SizedBox(height: 24),

                // Subscribe button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity, height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _selectedPlan == 0 ? null : AppColors.primaryGradient,
                        color: _selectedPlan == 0 ? (isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade300) : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedPlan == 0 ? null : [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton(
                        onPressed: _selectedPlan == 0 ? null : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('In-app purchase coming soon!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _selectedPlan == 0 ? 'Current Plan' : 'Subscribe to ${_plans[_selectedPlan].name}',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: _selectedPlan == 0
                                ? (isDark ? Colors.white30 : Colors.black26)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Cancel anytime. Auto-renews unless cancelled 24h before renewal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withOpacity(0.20) : Colors.black26, height: 1.5),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, int index, bool isDark) {
    final isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)]
              : (isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient)))
                      : null,
                ),
                const SizedBox(width: 14),
                Text(plan.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const Spacer(),
                if (plan.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: AppColors.primaryGradient),
                    child: const Text('POPULAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(plan.period,
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16,
                          color: isSelected ? AppColors.primary : AppColors.success.withOpacity(0.5)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f, style: TextStyle(fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

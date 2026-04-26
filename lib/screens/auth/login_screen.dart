import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../home/main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final email = _emailC.text.trim();
    final pass = _passC.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();
      await auth.signIn(email: email, password: pass);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
                )
              : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('A',
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your AI journey',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black54,
                  ),
                ),

                const SizedBox(height: 40),

                // Error
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),

                // Email
                _buildLabel('Email'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon:
                        Icon(Icons.mail_outline, color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: 20),

                // Password
                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passC,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _showForgotPassword(context);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login button
                SizedBox(
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
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Sign In',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Divider
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: isDark
                                ? Colors.white12
                                : Colors.black12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white30
                                  : Colors.black38)),
                    ),
                    Expanded(
                        child: Divider(
                            color: isDark
                                ? Colors.white12
                                : Colors.black12)),
                  ],
                ),

                const SizedBox(height: 30),

                // Google sign in placeholder
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement Google Sign-In
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Text('G',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    label: Text('Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white70 : Colors.black87,
                        )),
                  ),
                ),

                const SizedBox(height: 30),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black45,
                          )),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final emailC = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Enter your email to receive a reset link',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 20),
            TextField(
              controller: emailC,
              decoration: const InputDecoration(hintText: 'Email address'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (emailC.text.isNotEmpty) {
                    await context
                        .read<AuthService>()
                        .resetPassword(emailC.text.trim());
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset link sent!')),
                    );
                  }
                },
                child: const Text('Send Reset Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

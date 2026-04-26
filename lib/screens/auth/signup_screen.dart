import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../home/main_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    final pass = _passC.text.trim();
    final confirm = _confirmC.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();
      await auth.signUp(email: email, password: pass, displayName: name);
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
                const SizedBox(height: 20),

                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 20),

                const Text('Create Account',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Start your AI journey today',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54,
                    )),

                const SizedBox(height: 36),

                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),

                _label('Full Name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameC,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: 20),

                _label('Email'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.mail_outline, color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: 20),

                _label('Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passC,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Min 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _label('Confirm Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Re-enter password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: 32),

                // Signup button
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
                      onPressed: _loading ? null : _signup,
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
                          : const Text('Create Account',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black45)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            )),
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
}

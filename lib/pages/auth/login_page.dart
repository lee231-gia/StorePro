// import 'package:flutter/material.dart';

// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       const Scaffold(body: Center(child: Text('Login')));
// }

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/shared_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      showSnack(context, 'Please fill in all fields.', isError: true);
      return;
    }

    setState(() => _loading = true);
    final error = await AuthRepository.login(email, pass);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showSnack(context, error, isError: true);
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // ── TITLE ────────────────────────────────────
              const Center(
                child: Column(
                  children: [
                    Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: kDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Sign in to your StorePro account',
                      style: TextStyle(color: kGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── EMAIL ─────────────────────────────────────
              fieldLabel('Email'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: AppInput.field(
                  'Enter your email',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 18),

              // ── PASSWORD ──────────────────────────────────
              fieldLabel('Password'),
              TextField(
                controller: _passCtrl,
                obscureText: !_showPass,
                decoration: AppInput.field(
                  'Enter your password',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _showPass ? Icons.visibility : Icons.visibility_off,
                      color: kGrey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),

              // ── FORGOT PASSWORD ───────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: kRed, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── LOGIN BUTTON ──────────────────────────────
              PrimaryButton(label: 'Login', onTap: _login, isLoading: _loading),

              const SizedBox(height: 16),

              // ── SIGN UP LINK ──────────────────────────────
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: kGrey, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.signup,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: kRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

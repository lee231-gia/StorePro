import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/shared_widgets.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();

  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;
  String _selectedQuestion = 'What is your mother\'s maiden name?';

  final List<String> _questions = [
    'What is your mother\'s maiden name?',
    'What was the name of your first pet?',
    'What city were you born in?',
    'What is the name of your elementary school?',
    'What was your childhood nickname?',
  ];

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _storeCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final answer = _answerCtrl.text.trim();

    if (first.isEmpty ||
        last.isEmpty ||
        email.isEmpty ||
        username.isEmpty ||
        pass.isEmpty ||
        answer.isEmpty) {
      showSnack(context, 'Please fill in all required fields.', isError: true);
      return;
    }
    if (pass.length < 6) {
      showSnack(
        context,
        'Password must be at least 6 characters.',
        isError: true,
      );
      return;
    }
    if (pass != confirm) {
      showSnack(context, 'Passwords do not match.', isError: true);
      return;
    }

    setState(() => _loading = true);
    final error = await AuthRepository.signUp(
      email: email,
      password: pass,
      firstName: first,
      lastName: last,
      username: username,
      storeName: _storeCtrl.text.trim(),
      securityQuestion: _selectedQuestion,
      securityAnswer: answer,
    );
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              Center(
                child: Column(
                  children: [
                    Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Join StorePro today',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('First Name'),
                        TextField(
                          controller: _firstCtrl,
                          decoration: AppInput.field(context, 'First name'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('Last Name'),
                        TextField(
                          controller: _lastCtrl,
                          decoration: AppInput.field(context, 'Last name'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              fieldLabel('Store Name (optional)'),
              TextField(
                controller: _storeCtrl,
                decoration: AppInput.field(context, 
                  'Enter store name',
                  icon: Icons.storefront_outlined,
                ),
              ),

              const SizedBox(height: 14),

              fieldLabel('Email'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: AppInput.field(context, 
                  'Enter email',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 14),

              fieldLabel('Username'),
              TextField(
                controller: _usernameCtrl,
                decoration: AppInput.field(context, 
                  'Choose a username',
                  icon: Icons.alternate_email,
                ),
              ),

              const SizedBox(height: 14),

              fieldLabel('Password'),
              TextField(
                controller: _passCtrl,
                obscureText: !_showPass,
                decoration: AppInput.field(context, 
                  'Min. 6 characters',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _showPass ? Icons.visibility : Icons.visibility_off,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              fieldLabel('Confirm Password'),
              TextField(
                controller: _confirmCtrl,
                obscureText: !_showConfirm,
                decoration: AppInput.field(context, 
                  'Re-enter password',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _showConfirm ? Icons.visibility : Icons.visibility_off,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              sectionLabel('Security Question (for password recovery)'),
              DropdownButtonFormField<String>(
                initialValue: _selectedQuestion,
                decoration: AppInput.field(context, 'Select a question'),
                items: _questions
                    .map(
                      (q) => DropdownMenuItem(
                        value: q,
                        child: Text(q, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedQuestion = v);
                },
              ),

              const SizedBox(height: 12),

              fieldLabel('Your Answer'),
              TextField(
                controller: _answerCtrl,
                decoration: AppInput.field(context, 
                  'Enter your answer',
                  icon: Icons.security_outlined,
                ),
              ),

              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Create Account',
                onTap: _createAccount,
                isLoading: _loading,
              ),

              const SizedBox(height: 16),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

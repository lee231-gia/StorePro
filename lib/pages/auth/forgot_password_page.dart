// import 'package:flutter/material.dart';

// class ForgotPasswordPage extends StatelessWidget {
//   const ForgotPasswordPage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       const Scaffold(body: Center(child: Text('Forgot Password')));
// }

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/shared_widgets.dart';

// 4-step flow: Username → Security Question → OTP → New Password
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 0; // 0=username, 1=question, 2=otp, 3=new password
  bool _loading = false;

  // ── STEP DATA ─────────────────────────────────────────────
  String _storeId = '';
  String _question = '';
  String _otp = ''; // shown to user after answer verified
  String _resetEmail = '';

  final _usernameCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _answerCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ── STEP 0: Find account by username ──────────────────────
  Future<void> _submitUsername() async {
    if (_usernameCtrl.text.trim().isEmpty) {
      showSnack(context, 'Enter your username.', isError: true);
      return;
    }
    await _runLoading(() async {
      final result = await AuthRepository.getSecurityQuestion(
        _usernameCtrl.text.trim(),
      ).timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (!mounted) return;

      if (result == null) {
        showSnack(context, 'Username not found or network unavailable.', isError: true);
        return;
      }
      setState(() {
        _storeId = result['storeId'];
        _question = result['question'];
        _resetEmail = result['email'] ?? '';
        _step = 1;
      });
    });
  }

  // ── STEP 1: Verify security answer → get OTP ──────────────
  Future<void> _submitAnswer() async {
    if (_answerCtrl.text.trim().isEmpty) {
      showSnack(context, 'Enter your answer.', isError: true);
      return;
    }
    await _runLoading(() async {
      final result = await AuthRepository.verifySecurityAnswer(
        storeId: _storeId,
        answer: _answerCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
      ).timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (!mounted) return;

      if (result == null) {
        showSnack(context, 'Incorrect answer or network unavailable.', isError: true);
        return;
      }
      setState(() {
        _otp = result['otp'] ?? '';
        _resetEmail = result['email'] ?? _resetEmail;
        _step = 2;
      });
    });
  }

  // ── STEP 2: Verify OTP ────────────────────────────────────
  Future<void> _submitOtp() async {
    if (_otpCtrl.text.trim().isEmpty) {
      showSnack(context, 'Enter the OTP.', isError: true);
      return;
    }
    if (_otpCtrl.text.trim() != _otp) {
      showSnack(context, 'Incorrect OTP.', isError: true);
      return;
    }
    setState(() => _step = 3);
  }

  // ── STEP 3: Set new password ──────────────────────────────
  Future<void> _submitNewPassword() async {
    await _runLoading(() async {
      final error = await AuthRepository.sendPasswordResetEmail(
        _resetEmail,
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => 'Password reset request timed out.',
      );
      if (!mounted) return;
      if (error != null) {
        showSnack(context, error, isError: true);
        return;
      }

      showSnack(context, 'Password reset link sent to $_resetEmail.');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  Future<void> _runLoading(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Forgot Password',
        context: context,
        showMenu: false,
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── STEP INDICATOR ────────────────────────────
              _buildStepIndicator(),
              const SizedBox(height: 28),

              // ── STEP CONTENT ──────────────────────────────
              if (_step == 0) _buildStep0(),
              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP INDICATOR ────────────────────────────────────────
  Widget _buildStepIndicator() {
    final labels = ['Username', 'Security', 'OTP', 'Password'];

    return Row(
      children: List.generate(4, (i) {
        final active = i <= _step;

        return Expanded(
          child: Column(
            children: [
              Text(
                labels[i],
                style: TextStyle(
                  color: active ? kRed : Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Container(height: 4, color: active ? kRed : Colors.grey.shade300),
            ],
          ),
        );
      }),
    );
  }

  // ── STEP 0: USERNAME ──────────────────────────────────────
  Widget _buildStep0() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Enter your username',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: kDark,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'We\'ll look up your account.',
        style: TextStyle(color: kGrey, fontSize: 13),
      ),
      const SizedBox(height: 20),
      fieldLabel('Username'),
      TextField(
        controller: _usernameCtrl,
        decoration: AppInput.field(
          'Enter username',
          icon: Icons.alternate_email,
        ),
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'Continue',
        onTap: _submitUsername,
        isLoading: _loading,
      ),
    ],
  );

  // ── STEP 1: SECURITY QUESTION ─────────────────────────────
  Widget _buildStep1() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Security Question',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: kDark,
        ),
      ),
      const SizedBox(height: 16),
      appCard(
        child: Text(
          _question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kDark,
          ),
        ),
      ),
      const SizedBox(height: 12),
      fieldLabel('Your Answer'),
      TextField(
        controller: _answerCtrl,
        decoration: AppInput.field(
          'Enter your answer',
          icon: Icons.security_outlined,
        ),
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'Verify Answer',
        onTap: _submitAnswer,
        isLoading: _loading,
      ),
    ],
  );

  // ── STEP 2: OTP ───────────────────────────────────────────
  Widget _buildStep2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Enter OTP',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: kDark,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Your OTP is shown below. It expires in 10 minutes.',
        style: TextStyle(color: kGrey, fontSize: 13),
      ),
      const SizedBox(height: 16),

      // ── OTP DISPLAY BOX ───────────────────────────────────
      // Show the OTP on screen (system-generated, owner saves it)
      appCard(
        color: kRedLight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.key, color: kRed, size: 22),
            const SizedBox(width: 12),
            Text(
              'OTP: $_otp',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kRed,
                letterSpacing: 6,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),
      fieldLabel('Enter OTP'),
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: AppInput.field(
          'Enter 6-digit OTP',
          icon: Icons.pin_outlined,
        ),
      ),
      const SizedBox(height: 12),
      PrimaryButton(
        label: 'Verify OTP',
        onTap: _submitOtp,
        isLoading: _loading,
      ),
    ],
  );

  // ── STEP 3: NEW PASSWORD ──────────────────────────────────
  Widget _buildStep3() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Request Password Reset',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: kDark,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Firebase will send a secure reset link to the account email.',
        style: TextStyle(color: kGrey, fontSize: 13),
      ),
      const SizedBox(height: 24),
      PrimaryButton(
        label: 'Send Reset Link',
        onTap: _submitNewPassword,
        isLoading: _loading,
      ),
    ],
  );
}

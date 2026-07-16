import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/shared_widgets.dart';

// 4-step flow: Username -> Security Question -> OTP -> New Password
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 0; // 0=username, 1=question, 2=otp, 3=new password
  bool _loading = false;

  String _storeId = '';
  String _question = '';
  String _otp = '';
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? PaletteDark.error : PaletteLight.error;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
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
              _buildStepIndicator(cs, errorColor),
              const SizedBox(height: 28),

              if (_step == 0) _buildStep0(cs),
              if (_step == 1) _buildStep1(cs),
              if (_step == 2) _buildStep2(cs, errorColor),
              if (_step == 3) _buildStep3(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme cs, Color errorColor) {
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
                  color: active ? cs.primary : cs.outlineVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 4,
                color: active ? cs.primary : cs.surfaceContainerHighest,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep0(ColorScheme cs) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Enter your username',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'We\'ll look up your account.',
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
      ),
      const SizedBox(height: 20),
      fieldLabel('Username'),
      TextField(
        controller: _usernameCtrl,
        decoration: AppInput.field(context, 
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

  Widget _buildStep1(ColorScheme cs) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Security Question',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 16),
      appCard(
        child: Text(
          _question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
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
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'Verify Answer',
        onTap: _submitAnswer,
        isLoading: _loading,
      ),
    ],
  );

  Widget _buildStep2(ColorScheme cs, Color errorColor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Enter OTP',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Your OTP is shown below. It expires in 10 minutes.',
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
      ),
      const SizedBox(height: 16),

      appCard(
        color: cs.primaryContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key, color: cs.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              'OTP: $_otp',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.primary,
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
        decoration: AppInput.field(context, 
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

  Widget _buildStep3(ColorScheme cs) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Request Password Reset',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Firebase will send a secure reset link to the account email.',
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
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

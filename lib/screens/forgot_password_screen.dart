import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/services/password_reset_service.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/widgets/auth_widgets.dart';

enum _ResetStep { email, otp, reset }

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthGradientBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  SizedBox(height: isSmallScreen ? 20 : 32),
                  const ForgotPasswordFlow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordModal extends StatelessWidget {
  const ForgotPasswordModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: const ForgotPasswordFlow(showClose: true),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({Key? key, this.showClose = false}) : super(key: key);

  final bool showClose;

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final PasswordResetService _resetService = PasswordResetService();

  _ResetStep _step = _ResetStep.email;
  bool _isLoading = false;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resetService.dispose();
    super.dispose();
  }

  String get _emailValue => _emailController.text.trim();

  String get _otpValue => _otpController.text.trim();

  int get _stepIndex {
    switch (_step) {
      case _ResetStep.email:
        return 1;
      case _ResetStep.otp:
        return 2;
      case _ResetStep.reset:
        return 3;
    }
  }

  String get _stepTitle {
    switch (_step) {
      case _ResetStep.email:
        return 'Reset Password';
      case _ResetStep.otp:
        return 'Verify OTP';
      case _ResetStep.reset:
        return 'Set New Password';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case _ResetStep.email:
        return 'Enter your email to receive a 6-digit code.';
      case _ResetStep.otp:
        return _emailValue.isEmpty
            ? 'Enter the 6-digit code sent to your email.'
            : 'Enter the 6-digit code sent to $_emailValue.';
      case _ResetStep.reset:
        return 'Choose a strong password to secure your account.';
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  void _stopResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 0);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Email must contain @';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a 6-digit code';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Include at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSendOtp({bool isResend = false}) async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final success = await _resetService.sendOtp(_emailValue);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _otpController.clear();
      _startResendTimer();
      setState(() => _step = _ResetStep.otp);
      _showSuccess(
        isResend
            ? 'OTP resent to $_emailValue'
            : 'OTP sent to $_emailValue',
      );
    } else {
      _showError(_resetService.lastError ?? 'Failed to send OTP');
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final success = await _resetService.verifyOtp(_emailValue, _otpValue);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _stopResendTimer();
      setState(() => _step = _ResetStep.reset);
      _showSuccess('OTP verified successfully');
    } else {
      _showError(_resetService.lastError ?? 'Invalid OTP');
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final success = await _resetService.resetPassword(
      _emailValue,
      _otpValue,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccess('Password reset successfully');
      Navigator.of(context).pop();
    } else {
      _showError(_resetService.lastError ?? 'Failed to reset password');
    }
  }

  String _resendLabel() {
    if (_resendSeconds == 0) {
      return 'Did not receive the code?';
    }
    final seconds = _resendSeconds.toString().padLeft(2, '0');
    return 'Resend available in 00:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.showClose)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: AppColors.textSecondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        AuthScreenHeader(
          icon: Icons.lock_reset_outlined,
          title: _stepTitle,
          subtitle: _stepSubtitle,
        ),
        const SizedBox(height: 20),
        Text(
          'Step $_stepIndex of 3',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 28),
        _buildStepForm(),
      ],
    );
  }

  Widget _buildStepForm() {
    switch (_step) {
      case _ResetStep.email:
        return Form(
          key: _emailFormKey,
          child: Column(
            children: [
              ModernAuthField(
                controller: _emailController,
                hintText: 'Enter your email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 24),
              ModernAuthButton(
                label: 'Send OTP',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleSendOtp,
              ),
              const SizedBox(height: 22),
              AuthHelperLink(
                text: 'Remember your password? ',
                linkText: 'Back to Login',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      case _ResetStep.otp:
        return Form(
          key: _otpFormKey,
          child: Column(
            children: [
              ModernAuthField(
                controller: _otpController,
                hintText: 'Enter 6-digit OTP',
                icon: Icons.lock_outline,
                keyboardType: TextInputType.number,
                validator: _validateOtp,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _resendLabel(),
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resendSeconds == 0 && !_isLoading
                      ? () => _handleSendOtp(isResend: true)
                      : null,
                  child: const Text('Resend OTP'),
                ),
              ),
              const SizedBox(height: 8),
              ModernAuthButton(
                label: 'Verify OTP',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleVerifyOtp,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        _stopResendTimer();
                        setState(() => _step = _ResetStep.email);
                      },
                child: const Text('Change email'),
              ),
              const SizedBox(height: 8),
              AuthHelperLink(
                text: 'Remember your password? ',
                linkText: 'Back to Login',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      case _ResetStep.reset:
        return Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              ModernAuthField(
                controller: _passwordController,
                hintText: 'Create a new password',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              ModernAuthField(
                controller: _confirmPasswordController,
                hintText: 'Confirm new password',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 24),
              ModernAuthButton(
                label: 'Reset Password',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleResetPassword,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _step = _ResetStep.otp),
                child: const Text('Back to OTP'),
              ),
              const SizedBox(height: 8),
              AuthHelperLink(
                text: 'Remember your password? ',
                linkText: 'Back to Login',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
    }
  }
}

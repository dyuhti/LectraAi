import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/services/auth_service.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';
import 'package:smart_lecture_notes/widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _selectedRole = 'Student';
  final List<String> _roles = ['Student', 'Teacher', 'Parent', 'Other'];

  @override
  void initState() {
    super.initState();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 3) {
      return 'Full name must be at least 3 characters';
    }
    return null;
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await _authService.signup(
        _fullNameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else {
        _showError(_authService.lastError ?? 'Signup failed');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 20 : 32),
                  
                  // Header with icon
                  const AuthScreenHeader(
                    icon: Icons.person_add_outlined,
                    title: 'Create Account',
                    subtitle: 'Sign up to get started today',
                  ),

                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // Signup Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Full Name Field
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: ModernAuthField(
                            controller: _fullNameController,
                            hintText: 'Enter your full name',
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            validator: _validateFullName,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Email Field
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 700),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: ModernAuthField(
                            controller: _emailController,
                            hintText: 'Enter your email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Password Field
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: ModernAuthField(
                            controller: _passwordController,
                            hintText: 'Create a password',
                            icon: Icons.lock_outlined,
                            isPassword: true,
                            validator: _validatePassword,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Confirm Password Field
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 900),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: ModernAuthField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm your password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: _validateConfirmPassword,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Role Selection
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.primaryLight.withOpacity(0.08),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              underline: const SizedBox(),
                              style: const TextStyle(color: AppColors.primary),
                              dropdownColor: Colors.white,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedRole = newValue);
                                }
                              },
                              items: _roles.map<DropdownMenuItem<String>>((role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 22 : 32),

                        // Sign Up Button
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1100),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: ModernAuthButton(
                            label: 'Create Account',
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _handleSignup,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Login Link
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1200),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: child,
                            );
                          },
                          child: AuthHelperLink(
                            text: 'Already have an account? ',
                            linkText: 'Sign In',
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.login);
                            },
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

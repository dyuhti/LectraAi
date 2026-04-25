import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

/// Premium modern text input field for authentication
class ModernAuthField extends StatefulWidget {
  const ModernAuthField({
    required this.controller, required this.hintText, required this.validator, Key? key,
    this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;
  final FormFieldValidator<String> validator;
  final IconData? icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  State<ModernAuthField> createState() => _ModernAuthFieldState();
}

class _ModernAuthFieldState extends State<ModernAuthField> {
  late bool _obscurePassword;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscurePassword = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: _isFocused ? 1.0 : 0.0, end: _isFocused ? 1.0 : 0.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -2 * value),
          child: child,
        );
      },
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        obscureText: _obscurePassword,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        onTap: () => setState(() => _isFocused = true),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryLight.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryLight.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryLight.withOpacity(0.55),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primaryLight,
              width: 2,
            ),
          ),
          prefixIcon: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: _isFocused ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5),
                )
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                )
              : null,
          errorStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Premium modern button for authentication
class ModernAuthButton extends StatefulWidget {
  const ModernAuthButton({
    required this.label, required this.onPressed, Key? key,
    this.isLoading = false,
  }) : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<ModernAuthButton> createState() => _ModernAuthButtonState();
}

class _ModernAuthButtonState extends State<ModernAuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _scaleController.forward();
  }

  void _onTapUp(_) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.95).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
        ),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium header for auth screens with icon and title
class AuthScreenHeader extends StatelessWidget {
  const AuthScreenHeader({
    required this.icon, required this.title, Key? key,
    this.subtitle,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated icon
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.14),
                  AppColors.primary.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 28),
        // Animated title
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              height: 1.2,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.75),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Premium helper link for auth screens
class AuthHelperLink extends StatefulWidget {
  const AuthHelperLink({
    required this.text, required this.linkText, required this.onTap, Key? key,
  }) : super(key: key);

  final String text;
  final String linkText;
  final VoidCallback onTap;

  @override
  State<AuthHelperLink> createState() => _AuthHelperLinkState();
}

class _AuthHelperLinkState extends State<AuthHelperLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: RichText(
            text: TextSpan(
              text: widget.text,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.75),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: widget.linkText,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: _isHovered
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: AppColors.primary,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium gradient background for auth screens
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({
    required this.child, Key? key,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5F8FF),
            Colors.white,
            Colors.white.withOpacity(0.98),
          ],
          stops: const [0, 0.4, 1],
        ),
      ),
      child: child,
    );
  }
}

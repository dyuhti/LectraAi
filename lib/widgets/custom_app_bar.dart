import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

/// Custom AppBar with built-in back button support
/// Usage: Replace all AppBar instances with this for consistency
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final IconThemeData? iconTheme;

  const CustomAppBar({
    required this.title, Key? key,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.titleStyle,
    this.bottom,
    this.elevation = 4,
    this.iconTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: titleStyle ??
            const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
      ),
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: elevation,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              tooltip: 'Back',
            )
          : null,
      actions: actions,
      iconTheme: iconTheme ?? const IconThemeData(color: AppColors.primary),
      centerTitle: false,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

/// Helper function to navigate to a named route
/// Parameters:
/// - context: BuildContext
/// - routeName: Name of the route from AppRoutes
/// - arguments: Optional arguments to pass to the route
/// - fullscreenDialog: Show as fullscreen dialog (non-modal)
/// - replaceAll: Replace entire navigation stack (true = no back button available)
Future<dynamic> navigateTo(
  BuildContext context, {
  required String routeName,
  Object? arguments,
  bool fullscreenDialog = false,
  bool replaceAll = false,
}) {
  if (replaceAll) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  if (fullscreenDialog) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          // This would need to be handled by your route generator
          return Container(); // Placeholder
        },
        fullscreenDialog: true,
      ),
    );
  }

  return Navigator.of(context).pushNamed(
    routeName,
    arguments: arguments,
  );
}

/// Helper function to pop current screen
void navigateBack(BuildContext context, {dynamic result}) {
  Navigator.of(context).pop(result);
}

/// Helper function to replace current screen
Future<dynamic> replaceScreen(
  BuildContext context, {
  required String routeName,
  Object? arguments,
}) {
  return Navigator.of(context).pushReplacementNamed(
    routeName,
    arguments: arguments,
  );
}

/// Helper function to navigate and clear stack
/// Useful for login -> home transitions
Future<dynamic> navigateAndClearStack(
  BuildContext context, {
  required String routeName,
  Object? arguments,
}) {
  return Navigator.of(context).pushNamedAndRemoveUntil(
    routeName,
    (route) => false,
    arguments: arguments,
  );
}

/// Navigation state helper
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Pop current route
  static void pop({dynamic result}) {
    navigatorKey.currentState?.pop(result);
  }

  /// Push named route
  static Future<dynamic> pushNamed(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState?.pushNamed(
          routeName,
          arguments: arguments,
        ) ??
        Future.value();
  }

  /// Push replacement route
  static Future<dynamic> pushReplacementNamed(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState?.pushReplacementNamed(
          routeName,
          arguments: arguments,
        ) ??
        Future.value();
  }

  /// Push named and remove until
  static Future<dynamic> pushNamedAndRemoveUntil(
    String routeName, {
    required RoutePredicate predicate, Object? arguments,
  }) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
          routeName,
          predicate,
          arguments: arguments,
        ) ??
        Future.value();
  }

  /// Get current route name
  static String? getCurrentRoute() {
    String? routeName;
    navigatorKey.currentState?.popUntil((route) {
      routeName = route.settings.name;
      return true;
    });
    return routeName;
  }
}

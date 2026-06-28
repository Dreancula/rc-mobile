import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/main_navigation/presentation/screens/main_navigation_screen.dart';

/// App Router - Handles all navigation routes
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => SplashScreen(
            onSplashComplete: () {
              // Navigation handled by SplashScreen
            },
          ),
        );

      case AppRoutes.auth:
        return MaterialPageRoute(
          builder: (_) => AuthScreen(
            onAuthSuccess: () {
              // Navigation handled by AuthScreen
            },
          ),
        );

      case AppRoutes.main:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

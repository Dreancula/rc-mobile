import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/database/hive_db.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'features/admin/presentation/screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveDb.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const RepublikCasualApp());
}

class RepublikCasualApp extends StatefulWidget {
  const RepublikCasualApp({super.key});

  @override
  State<RepublikCasualApp> createState() => _RepublikCasualAppState();
}

class _RepublikCasualAppState extends State<RepublikCasualApp> {
  bool _isInitialized = false;
  Widget _currentScreen = const SizedBox.shrink();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    final session = HiveDb.instance.getUserSession();
    final hasSession = session != null;
    final role = session?['role'] ?? 'user';

    setState(() {
      _currentScreen = SplashScreen(
        onSplashComplete: hasSession
            ? role == 'admin'
                ? () => _navigateToAdmin()
                : () => _navigateToMain()
            : () => _navigateToAuth(),
      );
      _isInitialized = true;
    });
  }

  void _navigateToAuth() {
    setState(() {
      _currentScreen = AuthScreen(
        onAuthSuccess: _onAuthSuccess,
      );
    });
  }

  void _onAuthSuccess() {
    final session = HiveDb.instance.getUserSession();
    final role = session?['role'] ?? 'user';

    setState(() {
      _currentScreen = role == 'admin'
          ? AdminScreen(onLogout: _navigateToAuth)
          : MainNavigationScreen(onLogout: _navigateToAuth);
    });
  }

  void _navigateToMain() {
    setState(() {
      _currentScreen = MainNavigationScreen(onLogout: _navigateToAuth);
    });
  }

  void _navigateToAdmin() {
    setState(() {
      _currentScreen = AdminScreen(onLogout: _navigateToAuth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Republik Casual',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isInitialized ? _currentScreen : _buildLoadingScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

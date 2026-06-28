import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isAdminMode = false;

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _toggleAdminMode() {
    setState(() {
      _isAdminMode = !_isAdminMode;
      _isLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: AppConstants.animationMedium,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isLogin
                  ? LoginScreen(
                      key: ValueKey('login_$_isAdminMode'),
                      onLoginSuccess: widget.onAuthSuccess,
                      onRegisterTap: _toggleAuthMode,
                      isAdminMode: _isAdminMode,
                    )
                  : RegisterScreen(
                      key: const ValueKey('register'),
                      onRegisterSuccess: widget.onAuthSuccess,
                      onLoginTap: _toggleAuthMode,
                    ),
            ),
          ),
          _buildAdminToggle(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryWhite,
      elevation: 0,
      leading: _isLogin
          ? null
          : IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.primaryBlack,
              ),
              onPressed: _toggleAuthMode,
            ),
      title: Text(
        _isLogin
            ? (_isAdminMode ? 'Admin' : 'Masuk')
            : 'Daftar',
        style: const TextStyle(
          color: AppColors.primaryBlack,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildAdminToggle() {
    if (!_isLogin) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderGrey, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isAdminMode ? Icons.admin_panel_settings : Icons.person_outline,
            size: 18,
            color: AppColors.softGrey,
          ),
          const SizedBox(width: 8),
          Text(
            _isAdminMode ? 'Admin Mode' : 'User Mode',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.softGrey,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleAdminMode,
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _isAdminMode
                    ? AppColors.blackGradient
                    : LinearGradient(
                        colors: [AppColors.borderGrey, AppColors.mediumGrey],
                      ),
              ),
              child: AnimatedAlign(
                duration: AppConstants.animationFast,
                alignment:
                    _isAdminMode ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

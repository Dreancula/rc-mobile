import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/language_provider.dart';
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
                  child: child,
                );
              },
              child: _isLogin
                  ? LoginScreen(
                      key: const ValueKey('login'),
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
      title: Consumer<LanguageProvider>(
        builder: (context, lp, _) {
          return Text(
            _isLogin
                ? (_isAdminMode
                    ? Translations.tr('admin_login', lp.locale)
                    : Translations.tr('login', lp.locale))
                : Translations.tr('register', lp.locale),
            style: const TextStyle(
              color: AppColors.primaryBlack,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Consumer<LanguageProvider>(
            builder: (context, lp, _) {
              return GestureDetector(
                onTap: () => _showLanguageSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlack.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryBlack.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.translate_rounded,
                        size: 16,
                        color: AppColors.primaryBlack.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lp.locale.name == 'en' ? 'EN' : 'ID',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlack.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _LanguageSheetAuth(langProvider: langProvider);
      },
    );
  }

  Widget _buildAdminToggle() {
    if (!_isLogin) return const SizedBox.shrink();

    return Consumer<LanguageProvider>(
      builder: (context, lp, _) {
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
                _isAdminMode
                    ? Translations.tr('admin_mode', lp.locale)
                    : Translations.tr('user_mode', lp.locale),
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
                    alignment: _isAdminMode
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
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
      },
    );
  }
}

class _LanguageSheetAuth extends StatefulWidget {
  final LanguageProvider langProvider;

  const _LanguageSheetAuth({required this.langProvider});

  @override
  State<_LanguageSheetAuth> createState() => _LanguageSheetAuthState();
}

class _LanguageSheetAuthState extends State<_LanguageSheetAuth>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = widget.langProvider;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                Translations.tr('select_language', lp.locale),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Translations.tr('choose_language', lp.locale),
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 20),
              _buildOption(
                label: 'English',
                isSelected: lp.locale == AppLocale.en,
                onTap: () {
                  lp.setLocale(AppLocale.en);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              _buildOption(
                label: 'Bahasa Indonesia',
                isSelected: lp.locale == AppLocale.id,
                onTap: () {
                  lp.setLocale(AppLocale.id);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0A0A0A)
            : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.language, size: 22, color: Color(0xFF0A0A0A)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF0A0A0A),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_rounded, size: 22, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

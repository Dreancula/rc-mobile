import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../home/presentation/screens/about_us_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onRegisterTap;
  final bool isAdminMode;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onRegisterTap,
    this.isAdminMode = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = widget.isAdminMode
        ? await HiveDb.instance.loginAdmin(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await HiveDb.instance.loginUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _failedAttempts = 0;
      await HiveDb.instance.saveUserSession(
        result['user'] as Map<String, dynamic>,
      );
      if (mounted) widget.onLoginSuccess();
    } else {
      final msg = result['message'] as String;
      if (msg == 'Password salah' && !widget.isAdminMode) {
        _failedAttempts++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password salah (${_failedAttempts}/3)'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (_failedAttempts >= 3) {
          _failedAttempts = 0;
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) _promptResetPassword();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  Future<void> _promptResetPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lupa Password?'),
        content: const Text('Anda sudah 3 kali salah memasukkan password. Ingin reset password?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti', style: TextStyle(color: AppColors.softGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: AppColors.pitchBlack, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _openForgotPassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildFormCard(),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 24),
              _buildRegisterLink(),
              const SizedBox(height: 16),
              _buildAboutLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final locale = context.watch<LanguageProvider>().locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLogo(size: 56),
        const SizedBox(height: 32),
        Text(
          widget.isAdminMode
              ? Translations.tr('admin_login', locale)
              : Translations.tr('welcome_back', locale),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.pitchBlack,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isAdminMode
              ? Translations.tr('sign_in_admin_desc', locale)
              : Translations.tr('sign_in_continue', locale),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.softGrey,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInputField(
              controller: _emailController,
              hintText: Translations.tr('email', context.watch<LanguageProvider>().locale),
              prefixIcon: Icons.alternate_email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final l = context.read<LanguageProvider>().locale;
                if (value == null || value.isEmpty) {
                  return Translations.tr('email_required', l);
                }
                if (!value.contains('@')) {
                  return Translations.tr('valid_email', l);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
              _buildInputField(
              controller: _passwordController,
              hintText: Translations.tr('password', context.watch<LanguageProvider>().locale),
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.softGrey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) {
                final l = context.read<LanguageProvider>().locale;
                if (value == null || value.isEmpty) {
                  return Translations.tr('password_required', l);
                }
                if (value.length < 6) {
                  return Translations.tr('password_min', l);
                }
                return null;
              },
            ),
            if (!widget.isAdminMode)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: _openForgotPassword,
                    child: Text(
                      Translations.tr('forgot_password', context.watch<LanguageProvider>().locale),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.softGrey,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.pitchBlack,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: AppColors.softGrey,
        ),
        prefixIcon: Icon(prefixIcon, color: AppColors.charcoal, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.lightGrey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.pitchBlack,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.blackGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.pitchBlack.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.pureWhite,
                  ),
                ),
              )
            : Text(
                widget.isAdminMode
                    ? Translations.tr('sign_in_admin', context.watch<LanguageProvider>().locale)
                    : Translations.tr('sign_in', context.watch<LanguageProvider>().locale),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildAboutLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutUsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Tentang Republik Casual',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.softGrey,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    if (widget.isAdminMode) return const SizedBox.shrink();

    final locale = context.watch<LanguageProvider>().locale;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Translations.tr('dont_have_account', locale),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.softGrey,
            ),
          ),
          GestureDetector(
            onTap: widget.onRegisterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.blackGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                Translations.tr('sign_up', locale),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

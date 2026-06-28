import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_logo.dart';

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
      await HiveDb.instance.saveUserSession(
        result['user'] as Map<String, dynamic>,
      );
      if (mounted) widget.onLoginSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              _buildDivider(),
              const SizedBox(height: 24),
              _buildRegisterLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLogo(size: 56),
        const SizedBox(height: 32),
        Text(
          widget.isAdminMode ? 'Admin Login' : 'Welcome Back',
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
              ? 'Sign in as administrator'
              : 'Sign in to continue shopping',
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
              hintText: 'Email address',
              prefixIcon: Icons.alternate_email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _passwordController,
              hintText: 'Password',
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
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Min. 6 characters';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
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
                widget.isAdminMode ? 'Sign In as Admin' : 'Sign In',
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.borderGrey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.softGrey,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.borderGrey)),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.isAdminMode
                ? "Not an admin? "
                : "Don't have an account? ",
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
                widget.isAdminMode ? 'User Login' : 'Sign Up',
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

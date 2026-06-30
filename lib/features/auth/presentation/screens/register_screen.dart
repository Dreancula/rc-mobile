import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../home/presentation/screens/about_us_screen.dart';
import '../../../../data/indonesia_regions.dart';
import '../../../../core/services/location_helper.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final VoidCallback onLoginTap;

  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    required this.onLoginTap,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;
  String _selectedProvince = '';
  String _selectedCity = '';
  List<String> _cities = [];
  bool _locating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final result = await LocationHelper.detectLocation();
    if (!mounted) return;
    setState(() => _locating = false);

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Match province
    String? matchedProvince = result.province;
    if (matchedProvince != null && !IndonesiaRegions.provinces.contains(matchedProvince)) {
      matchedProvince = null;
    }

    // Match city
    String? matchedCity = result.city;
    List<String> citiesInProvince = matchedProvince != null
        ? List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince] ?? [])
        : <String>[];

    if (matchedCity != null) {
      final found = IndonesiaRegions.findMatchingCity(matchedCity, citiesInProvince);
      if (found != null) {
        matchedCity = found;
      } else if (matchedProvince != null) {
        // City not in current province list — try searching all provinces
        final (prov, city) = IndonesiaRegions.findProvinceAndCity(matchedCity);
        if (prov != null && city != null) {
          matchedProvince = prov;
          matchedCity = city;
          citiesInProvince = List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince]!);
        } else {
          matchedCity = null;
        }
      } else {
        // No province detected — search all provinces
        final (prov, city) = IndonesiaRegions.findProvinceAndCity(matchedCity);
        if (prov != null && city != null) {
          matchedProvince = prov;
          matchedCity = city;
          citiesInProvince = List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince]!);
        } else {
          matchedCity = null;
        }
      }
    }

    setState(() {
      _selectedProvince = matchedProvince ?? '';
      _cities = citiesInProvince;
      _selectedCity = matchedCity ?? '';
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the terms and conditions'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await HiveDb.instance.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      address: _buildFullAddress(),
      phone: _phoneController.text.trim(),
      province: _selectedProvince,
      city: _selectedCity,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as Map<String, dynamic>;
      await HiveDb.instance.saveUserSession(user);
      if (!mounted) return;

      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: user['email'] as String,
              phone: phone,
              onVerified: () {
                Navigator.pop(context);
                if (mounted) widget.onRegisterSuccess();
              },
            ),
          ),
        );
      } else {
        if (mounted) widget.onRegisterSuccess();
      }
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
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildFormCard(),
              const SizedBox(height: 24),
              _buildTermsCheckbox(),
              const SizedBox(height: 24),
              _buildRegisterButton(),
              const SizedBox(height: 24),
              _buildLoginLink(),
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
          Translations.tr('create_account', locale),
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
          Translations.tr('sign_up_journey', locale),
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
            // Name Field
            _buildInputField(
              controller: _nameController,
              hintText: Translations.tr('full_name', context.watch<LanguageProvider>().locale),
              prefixIcon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
              validator: (value) {
                final l = context.read<LanguageProvider>().locale;
                if (value == null || value.isEmpty) {
                  return Translations.tr('name_required', l);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field
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

            // Password Field
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
            const SizedBox(height: 16),

            // Confirm Password Field
            _buildInputField(
              controller: _confirmPasswordController,
              hintText: Translations.tr('confirm_password', context.watch<LanguageProvider>().locale),
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.softGrey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              validator: (value) {
                final l = context.read<LanguageProvider>().locale;
                if (value == null || value.isEmpty) {
                  return Translations.tr('confirm_password_required', l);
                }
                if (value != _passwordController.text) {
                  return Translations.tr('password_no_match', l);
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionLabel(Translations.tr('shipping_address', context.watch<LanguageProvider>().locale)),
            const SizedBox(height: 12),

            // Phone Field
            _buildInputField(
              controller: _phoneController,
              hintText: Translations.tr('phone', context.watch<LanguageProvider>().locale),
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                final l = context.read<LanguageProvider>().locale;
                if (value == null || value.isEmpty) {
                  return Translations.tr('phone_required', l);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Location detect button
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _detectLocation,
                icon: _locating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, size: 20),
                label: Text(_locating ? 'Mendeteksi lokasi...' : 'Deteksi Lokasi Saya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pitchBlack,
                  side: const BorderSide(color: AppColors.pitchBlack),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Province Dropdown
            _buildDropdown(
              value: _selectedProvince,
              hint: 'Provinsi',
              icon: Icons.map_outlined,
              items: IndonesiaRegions.provinces,
              onChanged: (v) {
                setState(() {
                  _selectedProvince = v;
                  _selectedCity = '';
                  _cities = IndonesiaRegions.citiesByProvince[v] ?? [];
                });
              },
              validator: (v) => (v == null || v.isEmpty) ? 'Pilih provinsi' : null,
            ),
            const SizedBox(height: 16),

            // City Dropdown
            _buildDropdown(
              value: _selectedCity,
              hint: 'Kota/Kabupaten',
              icon: Icons.location_city_outlined,
              items: _cities,
              onChanged: (v) => setState(() => _selectedCity = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Pilih kota' : null,
            ),
            const SizedBox(height: 16),

            // Address Detail
            _buildInputField(
              controller: _addressController,
              hintText: 'Detail alamat (jalan, gang, no. rumah)',
              prefixIcon: Icons.location_on_outlined,
              keyboardType: TextInputType.streetAddress,
              maxLines: 2,
              validator: (value) {
                final l = context.read<LanguageProvider>().locale;
                if (value == null || value.isEmpty) {
                  return Translations.tr('address_required', l);
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.pitchBlack,
          letterSpacing: 0.3,
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Widget _buildDropdown({
    required String value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
        prefixIcon: Icon(icon, color: AppColors.charcoal, size: 20),
        filled: true,
        fillColor: AppColors.lightGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.pitchBlack, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      validator: validator ?? (v) => v == null || v.isEmpty ? hint : null,
      dropdownColor: AppColors.pureWhite,
    );
  }

  String _buildFullAddress() {
    final parts = <String>[];
    if (_addressController.text.trim().isNotEmpty) parts.add(_addressController.text.trim());
    if (_selectedCity.isNotEmpty) parts.add(_selectedCity);
    if (_selectedProvince.isNotEmpty) parts.add(_selectedProvince);
    return parts.join(', ');
  }

  Widget _buildTermsCheckbox() {
    final locale = context.watch<LanguageProvider>().locale;
    return GestureDetector(
      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _acceptTerms ? AppColors.pitchBlack : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptTerms ? AppColors.pitchBlack : AppColors.borderGrey,
                width: 1.5,
              ),
            ),
            child: _acceptTerms
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.pureWhite,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: Translations.tr('accept_terms', locale),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.softGrey,
                ),
                children: [
                  TextSpan(
                    text: Translations.tr('terms_of_service', locale),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pitchBlack,
                    ),
                  ),
                  TextSpan(
                    text: Translations.tr('and', locale),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.softGrey,
                    ),
                  ),
                  TextSpan(
                    text: Translations.tr('privacy_policy', locale),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pitchBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
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
        onPressed: _isLoading ? null : _handleRegister,
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
                Translations.tr('create_account', context.watch<LanguageProvider>().locale),
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

  Widget _buildLoginLink() {
    final locale = context.watch<LanguageProvider>().locale;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Translations.tr('already_have_account', locale),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.softGrey,
            ),
          ),
          GestureDetector(
            onTap: widget.onLoginTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.blackGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                Translations.tr('sign_in', locale),
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
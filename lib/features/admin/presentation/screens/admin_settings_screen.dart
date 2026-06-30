import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/localization/translations.dart';
import 'package:rc_mobile_v2/core/localization/language_provider.dart';
import '../../../auth/presentation/screens/forgot_password_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _db = HiveDb.instance;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  String? _avatarPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final session = _db.getUserSession();
    final name = session?['name'] as String? ?? 'Admin';
    final email = session?['email'] as String? ?? '';
    _nameCtrl = TextEditingController(text: name);
    _emailCtrl = TextEditingController(text: email);
    _avatarPath = _db.getAvatarPath();
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    final session = _db.getUserSession();
    if (session != null) {
      session['name'] = name;
      await _db.saveUserSession(session);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.of('profile_updated', context)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.pitchBlack,
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 256, maxHeight: 256);
    if (picked == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'admin_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(picked.path).copy('${dir.path}/$fileName');
      await _db.saveAvatarPath(saved.path);
      setState(() => _avatarPath = saved.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Translations.of('profile_settings', context).toUpperCase()} berhasil diupload'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: $e'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    await _db.removeAvatarPath();
    setState(() => _avatarPath = null);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LanguageProvider>().locale;
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.pureWhite,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.settings_rounded, color: AppColors.pureWhite, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(Translations.tr('admin_settings', locale), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _card(
                    Translations.tr('profile_settings', locale),
                    Icons.photo_camera_outlined,
                    [
                      _avatarSection(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _card(
                    Translations.tr('personal_info', locale),
                    Icons.person_outline_rounded,
                    [
                      _settingsField(Translations.tr('name', locale), _nameCtrl),
                      const SizedBox(height: 12),
                      _settingsField(Translations.tr('email_address', locale), _emailCtrl, readOnly: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _card(
                    Translations.tr('settings', locale),
                    Icons.translate_rounded,
                    [
                      _buildLanguageOption(),
                      const Divider(color: AppColors.borderGrey),
                      _buildChangePasswordOption(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4, shadowColor: AppColors.pitchBlack.withValues(alpha: 0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite),
                              ),
                            )
                          : Text('${Translations.tr('save', locale)} ${Translations.tr('settings', locale)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.softBlackGradient,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: _avatarPath != null && _avatarPath!.isNotEmpty
                      ? Image.file(
                          File(_avatarPath!),
                          fit: BoxFit.cover,
                          width: 72, height: 72,
                          errorBuilder: (_, _, _) => _initialPlaceholder(),
                        )
                      : _initialPlaceholder(),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.pitchBlack,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.pureWhite, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.pureWhite, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Translations.tr('profile_settings', context.watch<LanguageProvider>().locale), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                const SizedBox(height: 4),
                Text('Upload foto profil untuk tampilan sidebar', style: TextStyle(fontSize: 12, color: AppColors.softGrey)),
                const SizedBox(height: 8),
                if (_avatarPath != null && _avatarPath!.isNotEmpty)
                  GestureDetector(
                    onTap: _removeAvatar,
                    child: Text('${Translations.tr('delete', context.watch<LanguageProvider>().locale)} foto', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialPlaceholder() {
    return Center(
      child: Text('A',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.pureWhite.withValues(alpha: 0.7))),
    );
  }

  Widget _buildLanguageOption() {
    final locale = context.watch<LanguageProvider>().locale;
    return GestureDetector(
      onTap: () => _showLanguageSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  Translations.tr('language', locale),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.pitchBlack),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.pitchBlack,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    locale == AppLocale.en ? 'EN' : 'ID',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.pureWhite),
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: AppColors.softGrey),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _LanguageSheetAdmin(langProvider: langProvider);
      },
    );
  }

  Widget _buildChangePasswordOption() {
    final locale = context.watch<LanguageProvider>().locale;
    return GestureDetector(
      onTap: _openChangePassword,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.pitchBlack),
                const SizedBox(width: 10),
                Text(
                  Translations.tr('change_password', locale),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.pitchBlack),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: AppColors.softGrey),
          ],
        ),
      ),
    );
  }

  void _openChangePassword() {
    final locale = context.read<LanguageProvider>().locale;
    final session = _db.getUserSession();
    final email = session?['email'] as String? ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: email,
          title: Translations.tr('change_password', locale),
          readOnlyEmail: true,
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.pureWhite, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _settingsField(String label, TextEditingController controller, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: readOnly ? AppColors.offWhite : AppColors.lightGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
      ),
      style: TextStyle(
        fontSize: 14,
        color: readOnly ? AppColors.softGrey : AppColors.pitchBlack,
      ),
    );
  }
}

class _LanguageSheetAdmin extends StatefulWidget {
  final LanguageProvider langProvider;

  const _LanguageSheetAdmin({required this.langProvider});

  @override
  State<_LanguageSheetAdmin> createState() => _LanguageSheetAdminState();
}

class _LanguageSheetAdminState extends State<_LanguageSheetAdmin>
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
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

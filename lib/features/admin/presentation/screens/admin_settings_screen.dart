import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _nameCtrl = TextEditingController(text: 'Admin');
  final _emailCtrl = TextEditingController(text: 'admin@admin.com');
  bool _notifActive = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Pengaturan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _card(
                    'Profil',
                    Icons.person_outline_rounded,
                    [
                      _settingsField('Nama', _nameCtrl),
                      const SizedBox(height: 12),
                      _settingsField('Email', _emailCtrl),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _card(
                    'Keamanan',
                    Icons.lock_outline_rounded,
                    [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ubah Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.pitchBlack)),
                            const Icon(Icons.chevron_right, color: AppColors.softGrey),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _card(
                    'Notifikasi',
                    Icons.notifications_outlined,
                    [
                      SwitchListTile(
                        title: const Text('Notifikasi Push', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.pitchBlack)),
                        value: _notifActive,
                        onChanged: (v) => setState(() => _notifActive = v),
                        activeTrackColor: AppColors.pitchBlack,
                        inactiveThumbColor: AppColors.softGrey,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      SwitchListTile(
                        title: const Text('Notifikasi Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.pitchBlack)),
                        value: true,
                        onChanged: (v) {},
                        activeTrackColor: AppColors.pitchBlack,
                        inactiveThumbColor: AppColors.softGrey,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pengaturan berhasil disimpan'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4, shadowColor: AppColors.pitchBlack.withValues(alpha: 0.3),
                      ),
                      child: const Text('Simpan Pengaturan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  Widget _settingsField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: AppColors.lightGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
      ),
      style: const TextStyle(fontSize: 14, color: AppColors.pitchBlack),
    );
  }
}

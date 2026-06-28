import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'admin_dashboard.dart';
import 'admin_user_screen.dart';
import 'admin_product_screen.dart';
import 'admin_order_screen.dart';
import 'admin_category_screen.dart';
import 'admin_activity_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_wallet_screen.dart';
import 'admin_complaint_screen.dart';
import 'admin_voucher_screen.dart';

class AdminScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const AdminScreen({super.key, this.onLogout});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final HiveDb _db = HiveDb.instance;
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _logout() async {
    await _db.clearUserSession();
    if (mounted) widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.pitchBlack),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _menuItems[_selectedIndex].title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.pitchBlack),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.softBlackGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline, color: AppColors.pureWhite, size: 20),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.pitchBlack,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.softBlackGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.15), width: 2),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: AppColors.pureWhite, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text('Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pureWhite, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('admin@admin.com', style: TextStyle(fontSize: 13, color: AppColors.pureWhite.withValues(alpha: 0.5))),
                ],
              ),
            ),
            const Divider(color: AppColors.pureWhite, height: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = _selectedIndex == index;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.pureWhite.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            if (isSelected)
                              Container(
                                width: 3, height: 20,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.pureWhite, AppColors.mediumGrey]),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              )
                            else
                              const SizedBox(width: 15),
                            Icon(item.icon, color: isSelected ? AppColors.pureWhite : AppColors.pureWhite.withValues(alpha: 0.5), size: 22),
                            const SizedBox(width: 14),
                            Text(item.title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.pureWhite : AppColors.pureWhite.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: AppColors.pureWhite, height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                      SizedBox(width: 14),
                      Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return AdminDashboard(db: _db);
      case 1: return AdminUserScreen(db: _db);
      case 2: return AdminProductScreen(db: _db);
      case 3: return AdminOrderScreen(db: _db);
      case 4: return AdminCategoryScreen(db: _db);
      case 5: return AdminActivityScreen(db: _db);
      case 6: return const AdminWalletScreen();
      case 7: return AdminChatScreen(db: _db);
      case 8: return AdminVoucherScreen(db: _db);
      case 9: return const AdminComplaintScreen();
      case 10: return const AdminSettingsScreen();
      default: return const SizedBox();
    }
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  const _MenuItem({required this.title, required this.icon});
}

const _menuItems = [
  _MenuItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
  _MenuItem(title: 'Pengguna', icon: Icons.people_rounded),
  _MenuItem(title: 'Produk', icon: Icons.inventory_2_rounded),
  _MenuItem(title: 'Transaksi', icon: Icons.receipt_long_rounded),
  _MenuItem(title: 'Kategori', icon: Icons.category_rounded),
  _MenuItem(title: 'Riwayat', icon: Icons.history_rounded),
  _MenuItem(title: 'Dompet Digital', icon: Icons.account_balance_wallet_outlined),
  _MenuItem(title: 'Chat Pembeli', icon: Icons.chat_rounded),
  _MenuItem(title: 'Voucher', icon: Icons.confirmation_num_outlined),
  _MenuItem(title: 'Komplain', icon: Icons.feedback_outlined),
  _MenuItem(title: 'Pengaturan', icon: Icons.settings_rounded),
];

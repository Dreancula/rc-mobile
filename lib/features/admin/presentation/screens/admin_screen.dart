import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/services/notification_service.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/features/notifications/presentation/screens/notification_screen.dart';
import 'admin_dashboard.dart';
import 'admin_user_screen.dart';
import 'admin_product_screen.dart';
import 'admin_order_screen.dart';
import 'admin_category_screen.dart';
import 'admin_activity_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_wallet_screen.dart';
import 'admin_report_screen.dart';
import 'admin_complaint_screen.dart';
import 'admin_voucher_screen.dart';
import 'admin_review_screen.dart';

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _db.getUserSession();
  }

  void _logout() async {
    await _db.clearUserSession();
    if (mounted) widget.onLogout?.call();
  }

  List<_MenuItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _allMenuItems;
    return _allMenuItems
        .where((m) => m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
          _allMenuItems[_selectedIndex].title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationService>(
            builder: (context, notifService, _) {
              final count = notifService.unreadAdminCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.pitchBlack),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(recipient: 'admin'),
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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
      onDrawerChanged: (opened) {
        if (opened) setState(() {});
      },
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    final session = _db.getUserSession();
    final userName = session?['name'] as String? ?? 'Admin';
    final userEmail = session?['email'] as String? ?? 'admin@admin.com';
    final avatarPath = _db.getAvatarPath();
    final items = _filteredItems;
    final hasSearch = _searchQuery.isNotEmpty;

    return Drawer(
      width: 260,
      backgroundColor: AppColors.pitchBlack,
      child: SafeArea(
        child: Column(
          children: [
            // Profile
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.softBlackGradient,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: avatarPath != null
                          ? Image.file(
                              File(avatarPath),
                              fit: BoxFit.cover,
                              width: 48, height: 48,
                              errorBuilder: (_, _, _) => _avatarPlaceholder(userName),
                            )
                          : _avatarPlaceholder(userName),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.pureWhite)),
                        const SizedBox(height: 2),
                        Text(userEmail,
                          style: TextStyle(fontSize: 13, color: AppColors.pureWhite.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 14, color: AppColors.pureWhite),
                decoration: InputDecoration(
                  hintText: 'Cari menu...',
                  hintStyle: TextStyle(color: AppColors.pureWhite.withValues(alpha: 0.3), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.pureWhite.withValues(alpha: 0.3), size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: AppColors.pureWhite.withValues(alpha: 0.3), size: 20),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.pureWhite.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Menu list
            Expanded(
              child: hasSearch
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _menuItem(items[i], _allMenuItems.indexOf(items[i])),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        // Group 1: UTAMA
                        _groupLabel('Utama'),
                        _menuItem(_allMenuItems[0], 0), // Dashboard
                        const SizedBox(height: 4),
                        _divider(),
                        // Group 2: PRODUK
                        _groupLabel('Manajemen Produk'),
                        _menuItem(_allMenuItems[2], 2), // Produk
                        _menuItem(_allMenuItems[4], 4), // Kategori
                        _menuItem(_allMenuItems[9], 9), // Voucher
                        const SizedBox(height: 4),
                        _divider(),
                        // Group 3: KEUANGAN
                        _groupLabel('Transaksi & Keuangan'),
                        _menuItem(_allMenuItems[3], 3), // Transaksi
                        _menuItem(_allMenuItems[6], 6), // Dompet Digital
                        _menuItem(_allMenuItems[5], 5), // Riwayat
                        const SizedBox(height: 4),
                        _divider(),
                        // Group 4: ANALISIS
                        _groupLabel('Analisis & Laporan'),
                        _menuItem(_allMenuItems[7], 7), // Laporan
                        const SizedBox(height: 4),
                        _divider(),
                        // Group 5: PELANGGAN
                        _groupLabel('Pelanggan & Komunikasi'),
                        _menuItem(_allMenuItems[8], 8), // Chat Pembeli
                        _menuItem(_allMenuItems[10], 10), // Komplain
                        _menuItem(_allMenuItems[11], 11), // Ulasan
                        const SizedBox(height: 4),
                        _divider(),
                        // Group 6: SISTEM
                        _groupLabel('Sistem'),
                        _menuItem(_allMenuItems[1], 1), // Pengguna
                        _menuItem(_allMenuItems[12], 12), // Pengaturan
                        const SizedBox(height: 4),
                        _divider(),
                        // Logout
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 12),
                          child: InkWell(
                            onTap: _logout,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
                                  SizedBox(width: 14),
                                  Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.error)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Center(
      child: Text(initial,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pureWhite.withValues(alpha: 0.7))),
    );
  }

  Widget _groupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
      child: Text(label.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.pureWhite.withValues(alpha: 0.35), letterSpacing: 1.2)),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: AppColors.pureWhite.withValues(alpha: 0.08)),
    );
  }

  Widget _menuItem(_MenuItem item, int index) {
    final isSelected = _selectedIndex == index && _searchQuery.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.pureWhite.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _searchQuery = '';
          });
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Icon(item.icon,
                color: isSelected ? AppColors.pureWhite : AppColors.pureWhite.withValues(alpha: 0.45),
                size: 24),
              const SizedBox(width: 14),
              Text(item.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.pureWhite : AppColors.pureWhite.withValues(alpha: 0.55),
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return AdminDashboard(key: ValueKey('dashboard_${DateTime.now().millisecondsSinceEpoch}'), db: _db);
      case 1: return AdminUserScreen(db: _db);
      case 2: return AdminProductScreen(db: _db);
      case 3: return AdminOrderScreen(db: _db);
      case 4: return AdminCategoryScreen(db: _db);
      case 5: return AdminActivityScreen(db: _db);
      case 6: return const AdminWalletScreen();
      case 7: return AdminReportScreen(db: _db);
      case 8: return AdminChatScreen(db: _db);
      case 9: return AdminVoucherScreen(db: _db);
      case 10: return const AdminComplaintScreen();
      case 11: return AdminReviewScreen(key: ValueKey('reviews_${DateTime.now().millisecondsSinceEpoch}'), db: _db);
      case 12: return const AdminSettingsScreen();
      default: return const SizedBox();
    }
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  const _MenuItem({required this.title, required this.icon});
}

const _allMenuItems = [
  _MenuItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
  _MenuItem(title: 'Pengguna', icon: Icons.people_rounded),
  _MenuItem(title: 'Produk', icon: Icons.inventory_2_rounded),
  _MenuItem(title: 'Transaksi', icon: Icons.receipt_long_rounded),
  _MenuItem(title: 'Kategori', icon: Icons.category_rounded),
  _MenuItem(title: 'Riwayat', icon: Icons.history_rounded),
  _MenuItem(title: 'Dompet Digital', icon: Icons.account_balance_wallet_outlined),
  _MenuItem(title: 'Laporan', icon: Icons.description_rounded),
  _MenuItem(title: 'Chat Pembeli', icon: Icons.chat_rounded),
  _MenuItem(title: 'Voucher', icon: Icons.confirmation_num_outlined),
  _MenuItem(title: 'Komplain', icon: Icons.feedback_outlined),
  _MenuItem(title: 'Ulasan', icon: Icons.star_rounded),
  _MenuItem(title: 'Pengaturan', icon: Icons.settings_rounded),
];

import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen>
    with SingleTickerProviderStateMixin {
  final HiveDb _db = HiveDb.instance;
  late TabController _tabController;
  List<Map<String, dynamic>> _myVouchers = [];
  List<Map<String, dynamic>> _pointVouchers = [];
  int _pointsBalance = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final all = _db.getActiveVouchers();
    final redeemed = _db.getRedeemedVoucherIds();
    setState(() {
      _myVouchers = all.where((v) => redeemed.contains(v['id'])).toList();
      _pointVouchers = all.where((v) => v['isPointExchange'] == true).toList();
      _pointsBalance = _db.getPointsBalance();
    });
  }

  Future<void> _redeemVoucher(Map<String, dynamic> v) async {
    final cost = v['pointCost'] as int? ?? 0;
    if (_pointsBalance < cost) return;
    final name = v['name'] as String? ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tukar Poin'),
        content: Text('Tukarkan ${cost} poin untuk mendapatkan voucher "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pitchBlack,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tukarkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _db.deductPoints(cost);
      await _db.addRedeemedVoucherId(v['id'] as String? ?? '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher "$name" berhasil ditukarkan!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Voucher', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Points Balance Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.blackGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.stars_rounded, color: AppColors.pureWhite, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Poin',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.pureWhite.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_pointsBalance Poin',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_pointVouchers.isNotEmpty)
                  Text(
                    '${_pointVouchers.length} voucher tersedia',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.pureWhite.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          // Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withValues(alpha: 0.6),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: BoxDecoration(
                    color: AppColors.pitchBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.pureWhite,
                  unselectedLabelColor: AppColors.softGrey,
                  labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: 'Voucher Saya (${_myVouchers.length})'),
                    Tab(text: 'Tukar Poin (${_pointVouchers.length})'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRegularTab(),
                _buildPointTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularTab() {
    if (_myVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_num_outlined, size: 64, color: AppColors.softGrey),
            const SizedBox(height: 16),
            Text(
              'Belum ada voucher',
              style: AppTextStyles.heading4.copyWith(color: AppColors.softGrey),
            ),
            const SizedBox(height: 8),
            Text(
              'Tukarkan poin kamu untuk mendapatkan voucher',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myVouchers.length,
      itemBuilder: (context, index) => _buildVoucherCard(_myVouchers[index]),
    );
  }

  Widget _buildPointTab() {
    if (_pointVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 64, color: AppColors.softGrey),
            const SizedBox(height: 16),
            Text(
              'Belum ada voucher tukar poin',
              style: AppTextStyles.heading4.copyWith(color: AppColors.softGrey),
            ),
            const SizedBox(height: 8),
            Text(
              'Voucher penukaran poin akan muncul di sini',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pointVouchers.length,
      itemBuilder: (context, index) => _buildPointVoucherCard(_pointVouchers[index]),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> v) {
    final percent = (v['discountPercent'] as num?)?.toDouble() ?? 0;
    final name = v['name'] as String? ?? '';
    final createdAt = v['createdAt'] as String? ?? '';
    final date = DateTime.tryParse(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.primaryBlack, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusM - 1),
                bottomLeft: Radius.circular(AppConstants.radiusM - 1),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.confirmation_num, color: AppColors.pureWhite, size: 28),
                const SizedBox(height: 4),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Diskon ${percent.toStringAsFixed(0)}% untuk semua produk',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tersedia sejak ${date.day}/${date.month}/${date.year}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.softGrey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Text(
                'Aktif',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointVoucherCard(Map<String, dynamic> v) {
    final percent = (v['discountPercent'] as num?)?.toDouble() ?? 0;
    final name = v['name'] as String? ?? '';
    final cost = v['pointCost'] as int? ?? 0;
    final canRedeem = _pointsBalance >= cost;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: canRedeem ? AppColors.pitchBlack : AppColors.borderGrey,
          width: canRedeem ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
            decoration: BoxDecoration(
              gradient: AppColors.blackGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusM - 1),
                bottomLeft: Radius.circular(AppConstants.radiusM - 1),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard, color: AppColors.pureWhite, size: 26),
                const SizedBox(height: 4),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Diskon ${percent.toStringAsFixed(0)}% untuk semua produk',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$cost poin',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.pitchBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: GestureDetector(
              onTap: canRedeem ? () => _redeemVoucher(v) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: canRedeem ? AppColors.pitchBlack : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  canRedeem ? 'Tukar' : 'Kurang',
                  style: AppTextStyles.caption.copyWith(
                    color: canRedeem ? AppColors.pureWhite : AppColors.softGrey,
                    fontWeight: FontWeight.w600,
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

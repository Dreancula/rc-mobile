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

class _VoucherScreenState extends State<VoucherScreen> {
  final HiveDb _db = HiveDb.instance;
  List<Map<String, dynamic>> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  void _loadVouchers() {
    setState(() {
      _vouchers = _db.getActiveVouchers();
    });
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
        title: const Text('Voucher Saya', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: _vouchers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_num_outlined, size: 64, color: AppColors.softGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada voucher tersedia',
                    style: AppTextStyles.heading4.copyWith(color: AppColors.softGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voucher akan muncul di sini jika tersedia',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              itemCount: _vouchers.length,
              itemBuilder: (context, index) => _buildVoucherCard(_vouchers[index]),
            ),
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
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
              child: const Text(
                'Aktif',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

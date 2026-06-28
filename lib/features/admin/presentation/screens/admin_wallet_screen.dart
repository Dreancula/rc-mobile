import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  final HiveDb _db = HiveDb.instance;
  List<Map<String, dynamic>> _pendingTopUps = [];

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  void _loadPending() {
    setState(() {
      _pendingTopUps = _db.getPendingTopUps();
    });
  }

  Future<void> _confirmTopUp(String id, double amount, String userEmail) async {
    await _db.updateTopUpStatus(id, 'completed');
    final raw = _db.usersBox.get(userEmail);
    if (raw != null && raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      final currentBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0;
      data['walletBalance'] = currentBalance + amount;
      await _db.usersBox.put(userEmail, data);
    }
    _loadPending();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Top up dikonfirmasi'),
        backgroundColor: AppColors.primaryBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _rejectTopUp(String id) async {
    await _db.updateTopUpStatus(id, 'cancelled');
    _loadPending();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Top up ditolak'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        title: Text(
          'Top Up Dompet',
          style: AppTextStyles.heading4.copyWith(color: AppColors.primaryBlack),
        ),
        centerTitle: true,
      ),
      body: _pendingTopUps.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: AppColors.softGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada permintaan top up',
                    style: AppTextStyles.heading4.copyWith(
                      color: AppColors.softGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permintaan top up dari user akan muncul di sini',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.softGrey,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => _loadPending(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                itemCount: _pendingTopUps.length,
                itemBuilder: (context, index) {
                  final topup = _pendingTopUps[index];
                  return _buildTopUpCard(topup);
                },
              ),
            ),
    );
  }

  Widget _buildTopUpCard(Map<String, dynamic> topup) {
    final amount = (topup['amount'] as num?)?.toDouble() ?? 0;
    final id = topup['id'] as String? ?? '';
    final userName = topup['userName'] as String? ?? '';
    final userEmail = topup['userEmail'] as String? ?? '';
    final timestamp = topup['timestamp'] as String? ?? '';
    final date = DateTime.tryParse(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Text(userEmail, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
              ),
              Text(
                'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: AppTextStyles.heading4,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          if (date != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tanggal',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _confirmTopUp(id, amount, userEmail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusS),
                      ),
                    ),
                    child: const Text('Konfirmasi', style: AppTextStyles.buttonText),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _rejectTopUp(id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusS),
                      ),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

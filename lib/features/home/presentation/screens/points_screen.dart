import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/models/order_model.dart';
import 'voucher_screen.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  final HiveDb _db = HiveDb.instance;
  int _pointsBalance = 0;
  List<OrderModel> _completedOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final session = _db.getUserSession();
    final userId = session?['id'] ?? '';
    final orders = OrderRepository().getUserOrders(userId);
    setState(() {
      _pointsBalance = _db.getPointsBalance();
      _completedOrders = orders
          .where((o) => o.status == OrderStatus.delivered)
          .toList()
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
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
        title: const Text('Poin Saya', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Points Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.blackGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: AppColors.pureWhite,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_pointsBalance',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Poin',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.pureWhite.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.softGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kamu mendapat 1 poin untuk setiap Rp 1.000 belanja. '
                      'Kumpulkan poin dan tukarkan dengan voucher diskon!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.darkGrey,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tukar Poin Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoucherScreen()),
                ),
                icon: const Icon(Icons.card_giftcard_outlined, size: 20),
                label: const Text('Tukarkan Poin Saya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pitchBlack,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Riwayat Poin
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat Poin',
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_completedOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.softGrey),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada riwayat',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.softGrey,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_completedOrders.length, (i) {
                final order = _completedOrders[i];
                final pointsEarned = (order.totalPrice / 1000).floor();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderGrey.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_outlined,
                          size: 22,
                          color: AppColors.pitchBlack,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesanan #${order.id.substring(order.id.length - 6)}',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.items.length} item • Rp ${order.totalPrice.toStringAsFixed(0)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.softGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+$pointsEarned',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

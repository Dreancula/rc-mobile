import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/theme/app_text_styles.dart';
import 'package:rc_mobile_v2/core/constants/app_constants.dart';
import 'package:rc_mobile_v2/core/widgets/product_image.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';

class AdminActivityScreen extends StatefulWidget {
  final HiveDb db;
  const AdminActivityScreen({super.key, required this.db});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  late HiveDb _db;
  String _statusFilter = 'Semua';

  List<OrderModel> get _orders {
    final all = _db.getOrders();
    if (_statusFilter == 'Semua') return all;
    return all.where((o) => o.status.displayName == _statusFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _db = widget.db;
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: Column(
        children: [
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.history_rounded, color: AppColors.pureWhite, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Riwayat Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', ...OrderStatus.values.map((s) => s.displayName)].map((s) {
                      final sel = s == _statusFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: sel ? AppColors.blackGradient : null,
                              color: sel ? null : AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? AppColors.pureWhite : AppColors.softGrey))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.softGrey),
                        const SizedBox(height: 12),
                        const Text('Belum ada pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = switch (order.status) {
      OrderStatus.pending => AppColors.warning,
      OrderStatus.paid => AppColors.info,
      OrderStatus.processing => AppColors.info,
      OrderStatus.shipped => AppColors.info,
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled => AppColors.error,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_outlined, color: AppColors.pureWhite, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pesanan #${order.id.substring(max(0, order.id.length - 6))}',
                        style: AppTextStyles.labelLarge),
                    Text(order.userName, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(order.status.displayName,
                    style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              ...order.items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: ProductImage(imageUrl: item.imageUrl, width: 36, height: 36),
                  ),
                ),
              )),
              if (order.items.length > 3)
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('+${order.items.length - 3}', style: AppTextStyles.caption)),
                ),
              const Spacer(),
              Text(
                'Rp ${order.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            '${order.items.length} item • ${order.paymentMethod.displayName} • ${order.orderDate.toLocal().toString().substring(0, 10)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.softGrey),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../home/data/repositories/order_repository.dart';
import '../../../home/domain/models/order_model.dart';

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() => _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
  final HiveDb _db = HiveDb.instance;
  final OrderRepository _orderRepo = OrderRepository();
  List<Map<String, dynamic>> _complaints = [];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    setState(() {
      _complaints = _db.getComplaints();
    });
  }

  Future<void> _processRefund(String id, double refundAmount, String userEmail) async {
    await _db.updateComplaintStatus(id, 'resolved');
    await _db.deductRcBalance(refundAmount);
    final raw = _db.usersBox.get(userEmail);
    if (raw != null && raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      final currentBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0;
      data['walletBalance'] = currentBalance + refundAmount;
      await _db.usersBox.put(userEmail, data);
    }
    _loadComplaints();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengembalian dana Rp ${refundAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} berhasil'),
        backgroundColor: AppColors.primaryBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _rejectComplaint(String id) async {
    await _db.updateComplaintStatus(id, 'rejected');
    _loadComplaints();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Komplain ditolak'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDetail(Map<String, dynamic> c) {
    final orderId = c['orderId'] as String? ?? '';
    final order = _orderRepo.getOrderById(orderId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Complaint section
              _buildDetailHeader(c),
              const SizedBox(height: AppConstants.spacingM),
              _detailSection('Deskripsi Komplain', c['description'] as String? ?? ''),
              const SizedBox(height: AppConstants.spacingM),
              _buildPhotoSection(c),
              _buildRefundInfo(c),
              const SizedBox(height: AppConstants.spacingM),
              // Order section
              if (order != null) ...[
                const Divider(color: AppColors.borderGrey),
                const SizedBox(height: AppConstants.spacingM),
                Text('Detail Pesanan', style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppConstants.spacingM),
                _buildOrderDetail(order),
              ],
              const SizedBox(height: AppConstants.spacingXL),
              // Buttons
              if ((c['status'] as String? ?? '') == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _processRefund(
                              c['id'] as String? ?? '',
                              (c['refundAmount'] as num?)?.toDouble() ?? 0,
                              c['userEmail'] as String? ?? '',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusS),
                            ),
                          ),
                          child: const Text('Setuju & Refund', style: AppTextStyles.buttonText),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _rejectComplaint(c['id'] as String? ?? '');
                          },
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
              const SizedBox(height: AppConstants.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader(Map<String, dynamic> c) {
    final status = c['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isResolved = status == 'resolved';
    final statusColor = isPending ? AppColors.warning : (isResolved ? AppColors.success : AppColors.error);
    final statusText = isPending ? 'Menunggu' : (isResolved ? 'Disetujui' : 'Ditolak');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPending ? AppColors.warning.withValues(alpha: 0.1) : AppColors.lightGrey,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: Icon(Icons.feedback_outlined, color: isPending ? AppColors.warning : AppColors.darkGrey, size: 24),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c['userName'] as String? ?? '', style: AppTextStyles.bodyLarge),
              Text(c['userEmail'] as String? ?? '', style: AppTextStyles.caption),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          ),
          child: Text(statusText, style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _detailSection(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.softGrey)),
        const SizedBox(height: AppConstants.spacingS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: Text(content, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(Map<String, dynamic> c) {
    final photos = (c['photos'] as List?)?.cast<String>() ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto Bukti', style: AppTextStyles.labelMedium.copyWith(color: AppColors.softGrey)),
        const SizedBox(height: AppConstants.spacingS),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spacingS),
            itemBuilder: (_, i) {
              return Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS - 1),
                  child: photos[i].startsWith('http')
                      ? Image.network(photos[i], fit: BoxFit.cover)
                      : Image.file(File(photos[i]), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRefundInfo(Map<String, dynamic> c) {
    final status = c['status'] as String? ?? '';
    final isResolved = status == 'resolved';
    final refundAmount = (c['refundAmount'] as num?)?.toDouble() ?? 0;
    final orderTotal = (c['orderTotal'] as num?)?.toDouble() ?? 0;
    final createdAt = c['createdAt'] as String? ?? '';
    final date = DateTime.tryParse(createdAt);

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingM),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: isResolved ? AppColors.success.withValues(alpha: 0.1) : AppColors.lightGrey,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Row(
              children: [
                Icon(isResolved ? Icons.check_circle : Icons.account_balance_wallet_outlined, size: 18,
                    color: isResolved ? AppColors.success : AppColors.darkGrey),
                const SizedBox(width: AppConstants.spacingS),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pesanan', style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey)),
                    Text('Rp ${orderTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: AppTextStyles.labelLarge),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Pengembalian 30%', style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey)),
                    Text('Rp ${refundAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: AppTextStyles.labelLarge.copyWith(color: isResolved ? AppColors.success : AppColors.primaryBlack)),
                  ],
                ),
              ],
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: AppConstants.spacingS),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Diajukan: ${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.caption.copyWith(color: AppColors.softGrey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetail(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: const Icon(Icons.receipt_outlined, size: 20, color: AppColors.primaryBlack),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pesanan #${order.id.substring(max(0, order.id.length - 6))}',
                        style: AppTextStyles.labelLarge),
                    Text(order.orderDate.toLocal().toString().substring(0, 16),
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                ),
                child: Text(order.status.displayName,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Items
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusS - 1),
                    child: ProductImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${item.weight.toStringAsFixed(0)}g', style: AppTextStyles.caption.copyWith(color: AppColors.softGrey)),
                    ],
                  ),
                ),
                Text(
                  'Rp ${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  style: AppTextStyles.labelLarge,
                ),
              ],
            ),
          )),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: AppConstants.spacingS),
          // Shipping info
          if (order.courier != null) ...[
            _orderInfoRow('Kurir', '${order.courier} - ${order.courierService ?? ''}'),
            _orderInfoRow('Estimasi', order.estimatedDelivery ?? '-'),
          ],
          _orderInfoRow('Pengiriman', 'Rp ${order.shippingCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
          _orderInfoRow('Pembayaran', order.paymentMethod.displayName),
          const SizedBox(height: AppConstants.spacingS),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: AppConstants.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.labelLarge),
              Text(
                'Rp ${order.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryBlack, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey)),
          Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        ],
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
          'Komplain',
          style: AppTextStyles.heading4.copyWith(color: AppColors.primaryBlack),
        ),
        centerTitle: true,
      ),
      body: _complaints.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feedback_outlined, size: 64, color: AppColors.softGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada komplain',
                    style: AppTextStyles.heading4.copyWith(color: AppColors.softGrey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => _loadComplaints(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                itemCount: _complaints.length,
                itemBuilder: (context, index) => _buildComplaintCard(_complaints[index]),
              ),
            ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final status = c['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isResolved = status == 'resolved';
    final statusColor = isPending ? AppColors.warning : (isResolved ? AppColors.success : AppColors.error);
    final statusText = isPending ? 'Menunggu' : (isResolved ? 'Disetujui' : 'Ditolak');
    final refundAmount = (c['refundAmount'] as num?)?.toDouble() ?? 0;
    final orderNumber = c['orderNumber'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPending ? AppColors.warning.withValues(alpha: 0.1) : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                Icons.feedback_outlined,
                color: isPending ? AppColors.warning : AppColors.darkGrey,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['userName'] as String? ?? '', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text('Pesanan #$orderNumber', style: AppTextStyles.caption),
                  Text(
                    'Refund: Rp ${refundAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.darkGrey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Text(statusText, style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppConstants.spacingS),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.softGrey),
          ],
        ),
      ),
    );
  }
}

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

  // ===== FILTER STATUS =====
  String _statusFilter = 'Semua';

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

  // ===== GET COMPLAINTS WITH FILTER =====
  List<Map<String, dynamic>> get _filteredComplaints {
    if (_statusFilter == 'Semua') return _complaints;
    return _complaints.where((c) {
      final status = c['status'] as String? ?? 'pending';
      switch (_statusFilter) {
        case 'Menunggu':
          return status == 'pending';
        case 'Disetujui':
          return status == 'resolved';
        case 'Ditolak':
          return status == 'rejected';
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _processRefund(
    String id,
    double refundAmount,
    String userEmail,
  ) async {
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
        content: Text(
          'Pengembalian dana Rp ${refundAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} berhasil',
        ),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusL),
        ),
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
                  width: 40,
                  height: 4,
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
              _detailSection(
                'Deskripsi Komplain',
                c['description'] as String? ?? '',
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildPhotoSection(c),
              _buildRefundInfo(c),
              const SizedBox(height: AppConstants.spacingM),
              // Order section
              if (order != null) ...[
                const Divider(color: AppColors.borderGrey),
                const SizedBox(height: AppConstants.spacingM),
                const Text(
                  'Detail Pesanan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pitchBlack,
                  ),
                ),
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
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusS,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Setuju & Refund',
                            style: AppTextStyles.buttonText,
                          ),
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
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusS,
                              ),
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
    final statusColor = isPending
        ? AppColors.warning
        : (isResolved ? AppColors.success : AppColors.error);
    final statusText = isPending
        ? 'Menunggu'
        : (isResolved ? 'Disetujui' : 'Ditolak');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppColors.softBlackGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.feedback_outlined,
            color: isPending ? AppColors.warning : AppColors.pureWhite,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c['userName'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pitchBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                c['userEmail'] as String? ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.softGrey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailSection(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.softGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderGrey.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.pitchBlack,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(Map<String, dynamic> c) {
    final photos = (c['photos'] as List?)?.cast<String>() ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();
    final borderColor = AppColors.borderGrey.withValues(alpha: 0.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Bukti',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.softGrey,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
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
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
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
                Icon(
                  isResolved
                      ? Icons.check_circle
                      : Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: isResolved ? AppColors.success : AppColors.darkGrey,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pesanan',
                      style: TextStyle(fontSize: 11, color: AppColors.softGrey),
                    ),
                    Text(
                      'Rp ${orderTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pitchBlack,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Pengembalian 30%',
                      style: TextStyle(fontSize: 11, color: AppColors.softGrey),
                    ),
                    Text(
                      'Rp ${refundAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isResolved
                            ? AppColors.success
                            : AppColors.pitchBlack,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Diajukan: ${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: AppColors.softGrey),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
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
                  gradient: AppColors.softBlackGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  size: 16,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesanan #${order.id.substring(max(0, order.id.length - 6))}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pitchBlack,
                      ),
                    ),
                    Text(
                      order.orderDate.toLocal().toString().substring(0, 16),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.softGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status.displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Items
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.borderGrey.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: ProductImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.pitchBlack,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${item.weight.toStringAsFixed(0)}g',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.softGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rp ${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pitchBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: 8),
          // Shipping info
          if (order.courier != null) ...[
            _orderInfoRow(
              'Kurir',
              '${order.courier} - ${order.courierService ?? ''}',
            ),
            _orderInfoRow('Estimasi', order.estimatedDelivery ?? '-'),
          ],
          _orderInfoRow(
            'Pengiriman',
            'Rp ${order.shippingCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
          ),
          _orderInfoRow('Pembayaran', order.paymentMethod.displayName),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pitchBlack,
                ),
              ),
              Text(
                'Rp ${order.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pitchBlack,
                ),
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
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.softGrey),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.pitchBlack,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ===== MAIN BUILD =====
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ===== HEADER (TANPA TOMBOL DOWNLOAD) =====
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.softBlackGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.feedback_outlined,
                        color: AppColors.pureWhite,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Manajemen Komplain',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pitchBlack,
                      ),
                    ),
                    // ===== SPACER (tanpa tombol download) =====
                    const Spacer(),
                    // ===== TOMBOL DOWNLOAD DIHAPUS =====
                  ],
                ),
                const SizedBox(height: 12),
                // ===== FILTER CHIPS =====
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'].map(
                      (s) {
                        final sel = s == _statusFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _statusFilter = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: sel ? AppColors.blackGradient : null,
                                color: sel ? null : AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: sel
                                        ? AppColors.pureWhite
                                        : AppColors.softGrey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
          // ===== LIST COMPLAINTS =====
          Expanded(
            child: _filteredComplaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 48,
                          color: AppColors.softGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada komplain',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.softGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadComplaints(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      itemCount: _filteredComplaints.length,
                      itemBuilder: (context, index) =>
                          _buildComplaintCard(_filteredComplaints[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final status = c['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isResolved = status == 'resolved';
    final statusColor = isPending
        ? AppColors.warning
        : (isResolved ? AppColors.success : AppColors.error);
    final statusText = isPending
        ? 'Menunggu'
        : (isResolved ? 'Disetujui' : 'Ditolak');
    final refundAmount = (c['refundAmount'] as num?)?.toDouble() ?? 0;
    final orderNumber = c['orderNumber'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.softBlackGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.feedback_outlined,
                color: isPending ? AppColors.warning : AppColors.pureWhite,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['userName'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pitchBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pesanan #$orderNumber',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.softGrey,
                    ),
                  ),
                  Text(
                    'Refund: Rp ${refundAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.softGrey,
            ),
          ],
        ),
      ),
    );
  }
}

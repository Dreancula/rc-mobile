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

  // ===== FILTER STATUS =====
  String _statusFilter = 'Semua';

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

  // ===== GET TOP UPS WITH FILTER =====
  List<Map<String, dynamic>> get _filteredTopUps {
    if (_statusFilter == 'Semua') return _pendingTopUps;
    return _pendingTopUps.where((t) {
      final status = t['status'] as String? ?? 'pending';
      switch (_statusFilter) {
        case 'Menunggu':
          return status == 'pending';
        case 'Dikonfirmasi':
          return status == 'completed';
        case 'Ditolak':
          return status == 'cancelled';
        default:
          return true;
      }
    }).toList();
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
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ===== HEADER (KONSISTEN DENGAN TRANSAKSI & KOMPLAIN) =====
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
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.pureWhite,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Manajemen Dompet Digital',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pitchBlack,
                      ),
                    ),
                    const Spacer(),
                    // ===== TOMBOL DOWNLOAD (OPSIONAL) =====
                    // Bisa ditambahkan atau dihapus sesuai kebutuhan
                    // Saya kasih opsi, tinggal uncomment kalau mau
                    /*
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur download sedang dikembangkan'),
                                backgroundColor: AppColors.primaryBlack,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.download_rounded,
                              size: 18,
                              color: AppColors.pitchBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                    */
                  ],
                ),
                const SizedBox(height: 12),
                // ===== FILTER CHIPS =====
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', 'Menunggu', 'Dikonfirmasi', 'Ditolak']
                        .map((s) {
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
                                  gradient: sel
                                      ? AppColors.blackGradient
                                      : null,
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
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          // ===== LIST TOP UP =====
          Expanded(
            child: _filteredTopUps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: AppColors.softGrey,
                        ),
                        const SizedBox(height: 12),
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
                      itemCount: _filteredTopUps.length,
                      itemBuilder: (context, index) {
                        final topup = _filteredTopUps[index];
                        return _buildTopUpCard(topup);
                      },
                    ),
                  ),
          ),
        ],
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

    // ===== STATUS =====
    final status = topup['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isCompleted = status == 'completed';
    final statusColor = isPending
        ? AppColors.warning
        : (isCompleted ? AppColors.success : AppColors.error);
    final statusText = isPending
        ? 'Menunggu'
        : (isCompleted ? 'Dikonfirmasi' : 'Ditolak');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.softBlackGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
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
                      userName,
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
                      userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.softGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // ===== STATUS BADGE =====
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
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jumlah',
                style: TextStyle(fontSize: 12, color: AppColors.softGrey),
              ),
              Text(
                'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pitchBlack,
                ),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tanggal',
                  style: TextStyle(fontSize: 12, color: AppColors.softGrey),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.softGrey,
                  ),
                ),
              ],
            ),
          ],
          // ===== BUTTONS (HANYA UNTUK STATUS PENDING) =====
          if (isPending) ...[
            const SizedBox(height: 14),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Konfirmasi',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => _rejectTopUp(id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

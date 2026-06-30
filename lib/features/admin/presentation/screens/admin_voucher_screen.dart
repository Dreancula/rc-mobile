import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/theme/app_text_styles.dart';
import 'package:rc_mobile_v2/core/constants/app_constants.dart';

class AdminVoucherScreen extends StatefulWidget {
  final HiveDb db;
  const AdminVoucherScreen({super.key, required this.db});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  late HiveDb _db;
  List<Map<String, dynamic>> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _db = widget.db;
    _loadVouchers();
  }

  void _loadVouchers() {
    setState(() {
      _vouchers = _db.getVouchers();
    });
  }

  void _showForm({Map<String, dynamic>? voucher}) {
    final nameCtrl = TextEditingController(text: voucher?['name'] as String? ?? '');
    final percentCtrl = TextEditingController(
      text: voucher != null ? (voucher['discountPercent'] as num?)?.toStringAsFixed(0) ?? '' : '',
    );
    final pointCostCtrl = TextEditingController(
      text: voucher != null ? (voucher['pointCost'] as int?)?.toString() ?? '' : '',
    );
    bool isActive = voucher?['isActive'] as bool? ?? true;
    bool isPointExchange = voucher?['isPointExchange'] as bool? ?? false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusL)),
          title: Text(voucher == null ? 'Tambah Voucher' : 'Edit Voucher',
              style: AppTextStyles.heading4),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Voucher',
                      filled: true, fillColor: AppColors.lightGrey,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  TextField(
                    controller: percentCtrl,
                    decoration: InputDecoration(
                      labelText: 'Diskon (%)',
                      suffixText: '%',
                      filled: true, fillColor: AppColors.lightGrey,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Voucher Type
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipe Voucher', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setDialogState(() => isPointExchange = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !isPointExchange ? AppColors.pitchBlack : AppColors.pureWhite,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Regular',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: !isPointExchange ? AppColors.pureWhite : AppColors.pitchBlack,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setDialogState(() => isPointExchange = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isPointExchange ? AppColors.pitchBlack : AppColors.pureWhite,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Tukar Poin',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: isPointExchange ? AppColors.pureWhite : AppColors.pitchBlack,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isPointExchange) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    TextField(
                      controller: pointCostCtrl,
                      decoration: InputDecoration(
                        labelText: 'Harga Poin',
                        suffixText: 'poin',
                        filled: true, fillColor: AppColors.lightGrey,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingM),
                  Row(
                    children: [
                      const Text('Aktif', style: AppTextStyles.bodyMedium),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        onChanged: (v) => setDialogState(() => isActive = v),
                        activeColor: AppColors.primaryBlack,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final percentText = percentCtrl.text.trim();
                if (name.isEmpty || percentText.isEmpty) return;
                final percent = double.tryParse(percentText);
                if (percent == null || percent <= 0) return;

                if (voucher == null) {
                  final data = <String, dynamic>{
                    'id': 'v_${DateTime.now().millisecondsSinceEpoch}',
                    'name': name,
                    'discountPercent': percent,
                    'isActive': isActive,
                    'isPointExchange': isPointExchange,
                    'createdAt': DateTime.now().toIso8601String(),
                  };
                  if (isPointExchange) {
                    final cost = int.tryParse(pointCostCtrl.text.trim());
                    if (cost == null || cost <= 0) return;
                    data['pointCost'] = cost;
                  }
                  await _db.addVoucher(data);
                } else {
                  final updated = Map<String, dynamic>.from(voucher);
                  updated['name'] = name;
                  updated['discountPercent'] = percent;
                  updated['isActive'] = isActive;
                  updated['isPointExchange'] = isPointExchange;
                  if (isPointExchange) {
                    final cost = int.tryParse(pointCostCtrl.text.trim());
                    if (cost != null && cost > 0) updated['pointCost'] = cost;
                  } else {
                    updated.remove('pointCost');
                  }
                  await _db.updateVoucher(voucher['id'] as String, updated);
                }
                Navigator.pop(ctx);
                _loadVouchers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(voucher == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Voucher'),
        content: Text('Yakin ingin menghapus "${voucher['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteVoucher(voucher['id'] as String);
              Navigator.pop(ctx);
              _loadVouchers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.pureWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite,
        elevation: 4, child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.confirmation_num_rounded, color: AppColors.pureWhite, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Manajemen Voucher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.pitchBlack, borderRadius: BorderRadius.circular(20)),
                  child: Text('${_vouchers.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _vouchers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_num_outlined, size: 48, color: AppColors.softGrey),
                        const SizedBox(height: 12),
                        const Text('Belum ada voucher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadVouchers(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vouchers.length,
                      itemBuilder: (context, index) => _buildVoucherCard(_vouchers[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> v) {
    final isActive = v['isActive'] as bool? ?? true;
    final percent = (v['discountPercent'] as num?)?.toDouble() ?? 0;
    final isPointExchange = v['isPointExchange'] as bool? ?? false;
    final pointCost = v['pointCost'] as int?;

    return GestureDetector(
      onTap: () => _showForm(voucher: v),
      onLongPress: () => _confirmDelete(v),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: isActive ? AppColors.primaryBlack : AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.blackGradient : AppColors.softBlackGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                isPointExchange ? Icons.card_giftcard : Icons.confirmation_num,
                color: AppColors.pureWhite, size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(v['name'] as String? ?? '', style: AppTextStyles.labelLarge),
                      if (isPointExchange) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.pitchBlack.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Poin', style: AppTextStyles.caption.copyWith(
                            fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.pitchBlack,
                          )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPointExchange
                        ? '${pointCost ?? 0} poin • Diskon ${percent.toStringAsFixed(0)}%'
                        : 'Diskon ${percent.toStringAsFixed(0)}%',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Text(
                isActive ? 'Aktif' : 'Nonaktif',
                style: AppTextStyles.caption.copyWith(
                  color: isActive ? AppColors.success : AppColors.softGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

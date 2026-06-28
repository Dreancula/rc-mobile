import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final HiveDb _db = HiveDb.instance;
  final _customCtrl = TextEditingController();
  double _selectedAmount = 0;
  bool _showQris = false;

  static const double _adminFee = 2500;
  static const List<double> _presetAmounts = [50000, 100000, 200000, 500000];

  double get _totalPayment => _selectedAmount + _adminFee;

  String _formatRupiah(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String get _sessionEmail => _db.getUserSession()?['email'] as String? ?? '';
  String get _sessionName => _db.getUserSession()?['name'] as String? ?? '';

  void _selectAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _customCtrl.clear();
    });
  }

  void _useCustomAmount() {
    final text = _customCtrl.text.trim();
    if (text.isEmpty) return;
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) return;
    setState(() => _selectedAmount = amount);
  }

  void _proceedToPayment() {
    if (_selectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jumlah top up terlebih dahulu'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _showQris = true);
  }

  Future<void> _confirmPayment() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final record = {
      'id': id,
      'userEmail': _sessionEmail,
      'userName': _sessionName,
      'amount': _selectedAmount,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _db.addTopUpRecord(record);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pembayaran terkirim, menunggu konfirmasi admin'),
        backgroundColor: AppColors.primaryBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showQris) return _buildPaymentView();

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Top Up Dompet', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                gradient: AppColors.blackGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.pureWhite,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Saldo Dompet Digital',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.pureWhite.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'Rp ${_formatRupiah(_db.getWalletBalance())}',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingXL),

            Text('Pilih Nominal', style: AppTextStyles.heading4),
            const SizedBox(height: AppConstants.spacingM),

            // Preset Amounts
            Wrap(
              spacing: AppConstants.spacingM,
              runSpacing: AppConstants.spacingM,
              children: _presetAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return GestureDetector(
                  onTap: () => _selectAmount(amount),
                  child: AnimatedContainer(
                    duration: AppConstants.animationFast,
                    width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlack : AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlack : AppColors.borderGrey,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Rp ${_formatRupiah(amount)}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isSelected ? AppColors.pureWhite : AppColors.primaryBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Text(
                            '+ Rp 2.500',
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected
                                  ? AppColors.pureWhite.withValues(alpha: 0.7)
                                  : AppColors.softGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Custom Amount
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nominal Lainnya', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: 'Masukkan nominal',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.softGrey,
                            ),
                            prefixText: 'Rp ',
                            prefixStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryBlack,
                              fontWeight: FontWeight.w600,
                            ),
                            filled: true,
                            fillColor: AppColors.pureWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingM,
                              vertical: AppConstants.spacingM,
                            ),
                          ),
                          onChanged: (_) {
                            if (_selectedAmount != 0) {
                              setState(() => _selectedAmount = 0);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      GestureDetector(
                        onTap: _useCustomAmount,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingL,
                            vertical: AppConstants.spacingM,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlack,
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          ),
                          child: Text(
                            'Gunakan',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Fee and Total Breakdown
            if (_selectedAmount > 0) ...[
              const SizedBox(height: AppConstants.spacingL),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderGrey),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Column(
                  children: [
                    _buildFeeRow('Jumlah Top Up', 'Rp ${_formatRupiah(_selectedAmount)}'),
                    const SizedBox(height: AppConstants.spacingS),
                    _buildFeeRow('Biaya Admin', 'Rp ${_formatRupiah(_adminFee)}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingS),
                      child: Divider(height: 1),
                    ),
                    _buildFeeRow(
                      'Total Pembayaran',
                      'Rp ${_formatRupiah(_totalPayment)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spacingXL),

            // Top Up Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedAmount > 0 ? _proceedToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlack,
                  disabledBackgroundColor: AppColors.lightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: Text(
                  _selectedAmount > 0
                      ? 'Bayar Rp ${_formatRupiah(_totalPayment)}'
                      : 'Pilih Nominal',
                  style: AppTextStyles.buttonText.copyWith(
                    color: _selectedAmount > 0 ? AppColors.pureWhite : AppColors.softGrey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.heading4
              : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPaymentView() {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlack),
          onPressed: () => setState(() => _showQris = false),
        ),
        title: const Text('Pembayaran', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Amount
            Text(
              'Rp ${_formatRupiah(_totalPayment)}',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Scan QRIS untuk membayar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            // Breakdown below amount
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Text(
                'Top Up Rp ${_formatRupiah(_selectedAmount)} + Biaya Admin Rp ${_formatRupiah(_adminFee)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.darkGrey,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // QR Code Placeholder
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 120,
                    color: AppColors.primaryBlack.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    'QRIS',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.softGrey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingXL),

            // Info
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.darkGrey, size: 20),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      'Setelah pembayaran berhasil, admin akan mengkonfirmasi dan saldo akan otomatis bertambah.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: const Text(
                  'Sudah Bayar',
                  style: AppTextStyles.buttonText,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: () => setState(() => _showQris = false),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: Text(
                  'Batalkan',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.softGrey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

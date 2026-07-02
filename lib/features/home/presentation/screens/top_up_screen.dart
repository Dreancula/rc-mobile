import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
  bool _isLoading = false;

  static const double _adminFee = 2500;
  static const List<double> _presetAmounts = [50000, 100000, 200000, 500000];

  double get _totalPayment => _selectedAmount + _adminFee;

  String _formatRupiah(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
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
    if (amount == null || amount <= 0) {
      _showToast('Masukkan nominal yang valid');
      return;
    }
    if (amount < 10000) {
      _showToast('Minimal top up Rp 10.000');
      return;
    }
    setState(() => _selectedAmount = amount);
  }

  void _showToast(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primaryBlack,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _proceedToPayment() {
    if (_selectedAmount <= 0) {
      _showToast('Pilih nominal top up terlebih dahulu');
      return;
    }
    setState(() => _showQris = true);
  }

  Future<void> _confirmPayment() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final record = {
        'id': id,
        'userEmail': _sessionEmail,
        'userName': _sessionName,
        'amount': _selectedAmount,
        'adminFee': _adminFee,
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _db.addTopUpRecord(record);

      if (!mounted) return;
      _showToast(
        'Pembayaran terkirim, menunggu konfirmasi admin',
        isError: false,
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showToast('Terjadi kesalahan, silakan coba lagi');
      setState(() => _isLoading = false);
    }
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
      backgroundColor: AppColors.offWhite,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Pilih Nominal'),
            const SizedBox(height: 12),
            _buildPresetAmounts(),
            const SizedBox(height: 16),
            _buildCustomAmount(),
            if (_selectedAmount > 0) ...[
              const SizedBox(height: 16),
              _buildSummary(),
            ],
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ===== APP BAR =====
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.pureWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.pitchBlack,
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Top Up Dompet',
        style: AppTextStyles.heading4,
      ),
      centerTitle: true,
    );
  }

  // ===== BALANCE CARD =====
  Widget _buildBalanceCard() {
    final balance = _db.getWalletBalance();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.pitchBlack.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.pureWhite.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.pureWhite,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Dompet Digital',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.pureWhite.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${_formatRupiah(balance)}',
                  style: AppTextStyles.priceTextLarge.copyWith(
                    color: AppColors.pureWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== SECTION TITLE =====
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppColors.blackGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.priceText,
        ),
      ],
    );
  }

  // ===== PRESET AMOUNTS =====
  Widget _buildPresetAmounts() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _presetAmounts.map((amount) {
        final isSelected = _selectedAmount == amount;
        return GestureDetector(
          onTap: () => _selectAmount(amount),
          child: Container(
            width: (MediaQuery.of(context).size.width - 52) / 2,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.pitchBlack : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.pitchBlack : AppColors.borderGrey,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.pitchBlack.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  'Rp ${_formatRupiah(amount)}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected
                        ? AppColors.pureWhite
                        : AppColors.pitchBlack,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+ Rp 2.500',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.pureWhite.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===== CUSTOM AMOUNT =====
  Widget _buildCustomAmount() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nominal Lainnya',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.pitchBlack,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Masukkan nominal',
                    hintStyle: AppTextStyles.labelMedium,
                    prefixText: 'Rp ',
                    prefixStyle: AppTextStyles.priceTextSmall,
                    filled: true,
                    fillColor: AppColors.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) {
                    if (_selectedAmount != 0) {
                      setState(() => _selectedAmount = 0);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _useCustomAmount,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pitchBlack,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Gunakan',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== SUMMARY =====
  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          _summaryRow('Jumlah Top Up', 'Rp ${_formatRupiah(_selectedAmount)}'),
          const SizedBox(height: 8),
          _summaryRow('Biaya Admin', 'Rp ${_formatRupiah(_adminFee)}'),
          const Divider(height: 16),
          _summaryRow(
            'Total Pembayaran',
            'Rp ${_formatRupiah(_totalPayment)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.priceTextSmall
              : AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.priceText
              : AppTextStyles.labelMedium.copyWith(color: AppColors.darkGrey),
        ),
      ],
    );
  }

  // ===== SUBMIT BUTTON =====
  Widget _buildSubmitButton() {
    final isSelected = _selectedAmount > 0;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSelected ? _proceedToPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? AppColors.pitchBlack
              : AppColors.lightGrey,
          foregroundColor: AppColors.pureWhite,
          disabledBackgroundColor: AppColors.lightGrey,
          disabledForegroundColor: AppColors.softGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          isSelected
              ? 'Bayar Rp ${_formatRupiah(_totalPayment)}'
              : 'Pilih Nominal',
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? AppColors.pureWhite : AppColors.softGrey,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ===== PAYMENT VIEW =====
  // ============================================================
  Widget _buildPaymentView() {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.pitchBlack,
          onPressed: () => setState(() => _showQris = false),
        ),
        title: const Text(
          'Pembayaran',
          style: AppTextStyles.heading4,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(flex: 1),
            _buildPaymentAmount(),
            const SizedBox(height: 24),
            _buildQrCodePlaceholder(),
            const SizedBox(height: 24),
            _buildPaymentInfo(),
            const Spacer(flex: 1),
            _buildPaymentActions(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAmount() {
    return Column(
      children: [
        Text(
          'Rp ${_formatRupiah(_totalPayment)}',
          style: AppTextStyles.heading1,
        ),
        const SizedBox(height: 6),
        Text(
          'Scan QRIS untuk membayar',
          style: AppTextStyles.labelMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Top Up Rp ${_formatRupiah(_selectedAmount)} + Biaya Admin Rp ${_formatRupiah(_adminFee)}',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.darkGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodePlaceholder() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppColors.pitchBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: AppColors.pitchBlack.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pitchBlack,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'QRIS',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.darkGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Setelah pembayaran berhasil, admin akan mengkonfirmasi dan saldo akan otomatis bertambah.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.darkGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pitchBlack,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.pureWhite,
                    ),
                  )
                : Text(
                    'Sudah Bayar',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.pureWhite,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => setState(() => _showQris = false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Batalkan',
              style: AppTextStyles.priceTextSmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.softGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

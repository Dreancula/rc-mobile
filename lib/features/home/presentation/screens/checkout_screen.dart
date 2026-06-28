import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/services/shipping_calculator.dart';
import '../../domain/models/order_model.dart';
import 'top_up_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final VoidCallback onOrderSuccess;
  final VoidCallback onBack;

  const CheckoutScreen({
    super.key,
    required this.onOrderSuccess,
    required this.onBack,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartRepository _cart = CartRepository();
  final OrderRepository _orderRepo = OrderRepository();

  int _selectedPaymentIndex = 0;
  int? _selectedCourierIndex;
  bool _isProcessing = false;
  ShippingResult? _shippingResult;
  bool _shippingLoading = false;

  double? _voucherDiscount;
  bool _useVoucher = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Dompet Digital RC', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'COD (Bayar di Tempat)', 'icon': Icons.money},
  ];

  PaymentMethod get _selectedPaymentMethod =>
      _selectedPaymentIndex == 0 ? PaymentMethod.wallet : PaymentMethod.cod;

  double get _walletBalance => HiveDb.instance.getWalletBalance();

  double get _walletDiscount {
    if (_selectedPaymentMethod != PaymentMethod.wallet) return 0;
    final discount = _cart.subtotal * 0.02;
    return discount > 20000 ? 20000 : discount;
  }

  CourierOption? get _selectedCourier =>
      _selectedCourierIndex != null && _shippingResult != null
          ? _shippingResult!.options[_selectedCourierIndex!]
          : null;

  double get _shippingCost => _selectedCourier?.cost ?? 0;
  double get _voucherValue => _useVoucher ? (_voucherDiscount ?? 0) : 0;
  double get _grandTotal => _cart.subtotal + _shippingCost - _voucherValue - _walletDiscount;
  bool get _canUseVoucher =>
      _selectedPaymentMethod == PaymentMethod.wallet &&
      _voucherDiscount != null &&
      _voucherDiscount! > 0;

  @override
  void initState() {
    super.initState();
    _loadShipping();
    _voucherDiscount = HiveDb.instance.getVoucher();
  }

  Future<void> _loadShipping() async {
    final address = HiveDb.instance.getUserAddress();
    if (address.isEmpty) return;
    setState(() => _shippingLoading = true);
    final totalWeight = _cart.items.fold<double>(0, (sum, item) => sum + item.totalWeight);
    final result = ShippingCalculator.calculate(address, totalWeight);
    if (!mounted) return;
    setState(() {
      _shippingResult = result;
      _shippingLoading = false;
      if (result.options.isNotEmpty) _selectedCourierIndex = 0;
    });
  }

  Future<void> _processOrder() async {
    if (_selectedCourier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih kurir pengiriman'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == PaymentMethod.wallet && _walletBalance < _grandTotal) {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppConstants.spacingL),
              const Text('Saldo Tidak Mencukupi', style: AppTextStyles.heading4),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Saldo dompet digital Anda sebesar Rp ${_walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}\n'
                'Top up terlebih dahulu untuk melanjutkan.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: const Text('Top Up Sekarang'),
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Ganti Metode Bayar'),
              ),
            ],
          ),
        ),
      );

      if (result == true) {
        final topUpResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const TopUpScreen()),
        );
        if (topUpResult == true) {
          setState(() {});
        }
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final courier = _selectedCourier!;
      final orderId = await _orderRepo.createOrder(
        cartItems: _cart.items,
        subtotal: _cart.subtotal,
        shippingCost: _shippingCost,
        paymentMethod: _selectedPaymentMethod,
        courier: courier.name,
        courierService: courier.service,
        estimatedDelivery: courier.etd,
        voucherDiscount: _voucherValue,
      );

      if (_voucherValue > 0) {
        await HiveDb.instance.setVoucher(0);
      }

      if (_selectedPaymentMethod == PaymentMethod.wallet) {
        await HiveDb.instance.deductWallet(_grandTotal);
        _cart.clearCart();
        setState(() => _isProcessing = false);
        _showOrderSuccessDialog();
      } else if (_selectedPaymentMethod == PaymentMethod.qris) {
        setState(() => _isProcessing = false);
        _showQrisPayment(orderId);
      } else {
        _cart.clearCart();
        setState(() => _isProcessing = false);
        _showOrderSuccessDialog();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pesanan: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showQrisPayment(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primaryWhite,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 140, color: AppColors.pitchBlack),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text('Scan QRIS', style: AppTextStyles.heading3),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Scan QR code di atas\nuntuk melakukan pembayaran',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _orderRepo.confirmPayment(orderId);
                  _cart.clearCart();
                  _showOrderSuccessDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pitchBlack,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: const Text('Sudah Bayar'),
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cart.clearCart();
                widget.onBack();
              },
              child: Text(
                'Bayar Nanti',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.softGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text('Pesanan Berhasil!', style: AppTextStyles.heading3),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Terima kasih telah berbelanja\ndi Republik Casual',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Column(
                children: [
                  Text('Status Pesanan', style: AppTextStyles.caption),
                  Text(
                    _selectedPaymentMethod == PaymentMethod.wallet
                        ? 'Pembayaran Berhasil'
                        : _selectedPaymentMethod == PaymentMethod.qris
                            ? 'Menunggu Konfirmasi Admin'
                            : 'Sedang Diproses',
                    style: AppTextStyles.labelLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onOrderSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pitchBlack,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: const Text('Lihat Pesanan'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
            child: Text(
              'Kembali ke Beranda',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryAddress(),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildCourierSection(),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildPaymentMethod(),
                  if (_selectedPaymentMethod == PaymentMethod.wallet) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    _buildWalletInfo(),
                  ],
                  const SizedBox(height: AppConstants.spacingM),
                  if (_voucherDiscount != null) _buildVoucherSection(),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildOrderSummary(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlack),
        onPressed: widget.onBack,
      ),
      title: const Text('Checkout', style: AppTextStyles.heading4),
      centerTitle: true,
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    String? title,
    bool showTitle = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle && title != null) ...[
            Text(title, style: AppTextStyles.labelLarge),
            const SizedBox(height: AppConstants.spacingM),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    final address = HiveDb.instance.getUserAddress();
    final phone = HiveDb.instance.getUserPhone();
    final session = HiveDb.instance.getUserSession();
    final name = session?['name'] as String? ?? 'Customer';

    return _buildSectionCard(
      title: 'Alamat Pengiriman',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(phone, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  address,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierSection() {
    return _buildSectionCard(
      title: 'Kurir Pengiriman',
      child: _shippingLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : _shippingResult == null || _shippingResult!.options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Alamat tidak dikenali.\nPastikan alamat mencakup nama kota.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
                  ),
                )
              : Column(
                  children: [
                    if (_shippingResult!.estimatedDistanceKm > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.route_outlined, size: 16, color: AppColors.softGrey),
                            const SizedBox(width: 6),
                            Text(
                              'Estimasi jarak: ~${_shippingResult!.estimatedDistanceKm} km dari Depok',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ..._shippingResult!.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final opt = entry.value;
                      final isSelected = index == _selectedCourierIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCourierIndex = index),
                        child: AnimatedContainer(
                          duration: AppConstants.animationFast,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlack.withValues(alpha: 0.05)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlack
                                  : AppColors.borderGrey,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${opt.name} • ${opt.service}',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Estimasi ${opt.etd}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CartRepository.formatPrice(opt.cost),
                                style: AppTextStyles.priceText.copyWith(
                                  color: AppColors.pitchBlack,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle, size: 20, color: AppColors.pitchBlack),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildPaymentMethod() {
    return _buildSectionCard(
      title: 'Metode Pembayaran',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppConstants.spacingS,
        crossAxisSpacing: AppConstants.spacingS,
        childAspectRatio: 2.5,
        children: List.generate(_paymentMethods.length, (index) {
          final method = _paymentMethods[index];
          final isSelected = index == _selectedPaymentIndex;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedPaymentIndex = index;
              if (_selectedPaymentMethod == PaymentMethod.cod) {
                _useVoucher = false;
              }
            }),
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlack.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlack
                      : AppColors.borderGrey,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    method['icon'],
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryBlack
                        : AppColors.softGrey,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(
                    method['name'].toString().split(' ').first,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primaryBlack
                          : AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWalletInfo() {
    return _buildSectionCard(
      title: 'Dompet Digital RC',
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
                    const Text('Saldo Tersedia', style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: AppTextStyles.heading4,
                    ),
                  ],
                ),
              ),
              if (_walletBalance < _grandTotal)
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const TopUpScreen()),
                    );
                    if (result == true) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                      vertical: AppConstants.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlack,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Text(
                      'Top Up',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_walletDiscount > 0) ...[
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.discount_outlined,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      'Diskon dompet 2%: -${CartRepository.formatPrice(_walletDiscount)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_walletBalance < _grandTotal) ...[
            const SizedBox(height: AppConstants.spacingS),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      'Saldo tidak mencukupi. Top up terlebih dahulu.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return _buildSectionCard(
      title: 'Voucher Diskon',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _useVoucher
                      ? AppColors.primaryBlack.withValues(alpha: 0.1)
                      : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  Icons.confirmation_num,
                  color: _useVoucher ? AppColors.primaryBlack : AppColors.softGrey,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diskon ${CartRepository.formatPrice(_voucherDiscount!)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: _useVoucher ? AppColors.primaryBlack : AppColors.softGrey,
                      ),
                    ),
                    Text(
                      _canUseVoucher ? 'Berlaku untuk Dompet Digital RC' : 'Tidak tersedia untuk COD',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (_canUseVoucher)
                Switch(
                  value: _useVoucher,
                  onChanged: (v) => setState(() => _useVoucher = v),
                  activeThumbColor: AppColors.primaryBlack,
                )
              else
                Icon(Icons.lock_outline, color: AppColors.softGrey, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return _buildSectionCard(
      showTitle: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Pesanan', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppConstants.spacingM),
          ..._cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: ProductImage(
                        imageUrl: item.imageUrl,
                        width: 50,
                        height: 50,
                        borderRadius: AppConstants.radiusS,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.selectedSize} • ${item.weight} gr • x${item.quantity}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CartRepository.formatPrice(item.totalPrice),
                    style: AppTextStyles.priceTextSmall,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: AppConstants.spacingL),
          _buildSummaryRow(
            'Subtotal',
            CartRepository.formatPrice(_cart.subtotal),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          _buildSummaryRow(
            'Pengiriman',
            _shippingCost == 0
                ? 'GRATIS'
                : CartRepository.formatPrice(_shippingCost),
            valueColor: _shippingCost == 0 ? AppColors.success : null,
          ),
          if (_voucherValue > 0) ...[
            const SizedBox(height: AppConstants.spacingXS),
            _buildSummaryRow(
              'Diskon Voucher',
              '-${CartRepository.formatPrice(_voucherValue)}',
              valueColor: AppColors.success,
            ),
          ],
          if (_walletDiscount > 0) ...[
            const SizedBox(height: AppConstants.spacingXS),
            _buildSummaryRow(
              'Diskon Dompet',
              '-${CartRepository.formatPrice(_walletDiscount)}',
              valueColor: AppColors.success,
            ),
          ],
          const Divider(height: AppConstants.spacingL),
          _buildSummaryRow(
            'Total',
            CartRepository.formatPrice(_grandTotal),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? AppTextStyles.heading4 : AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: isBold
              ? AppTextStyles.heading4
              : AppTextStyles.priceTextSmall.copyWith(color: valueColor),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Pembayaran', style: AppTextStyles.caption),
                Text(
                  CartRepository.formatPrice(_grandTotal),
                  style: AppTextStyles.heading4,
                ),
              ],
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlack.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryWhite,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedPaymentMethod == PaymentMethod.wallet
                                  ? 'Bayar Dompet'
                                  : _selectedPaymentMethod == PaymentMethod.qris
                                      ? 'Bayar QRIS'
                                      : 'Buat Pesanan',
                              style: AppTextStyles.buttonText,
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            const Icon(
                              Icons.arrow_forward,
                              color: AppColors.primaryWhite,
                              size: 20,
                            ),
                          ],
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

import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/localization/translations.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/services/shipping_calculator.dart';
import '../../domain/models/order_model.dart';
import 'top_up_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final ValueChanged<String> onOrderSuccess;
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
  String? _lastOrderId;

  List<Map<String, dynamic>> _availableVouchers = [];
  Map<String, dynamic>? _selectedVoucher;
  bool _useVoucher = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Digital Wallet', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'COD', 'icon': Icons.money_outlined},
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

  double get _shippingCost {
    if (_cart.subtotal >= 500000) return 0;
    return _selectedCourier?.cost ?? 0;
  }

  double get _voucherValue {
    if (!_useVoucher || _selectedVoucher == null) return 0;
    final percent = (_selectedVoucher!['discountPercent'] as num).toDouble();
    return (_cart.subtotal * percent / 100).clamp(0, double.infinity);
  }

  double get _grandTotal =>
      _cart.subtotal + _shippingCost - _voucherValue - _walletDiscount;

  bool get _canUseVoucher =>
      _selectedPaymentMethod == PaymentMethod.wallet &&
      _availableVouchers.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadShipping();
    _availableVouchers = HiveDb.instance.getActiveVouchers();
  }

  // ============================================================
  // SHIPPING
  // ============================================================
  Future<void> _loadShipping() async {
    final city = HiveDb.instance.getUserCity();
    final address = HiveDb.instance.getUserAddress();
    if (address.isEmpty && city.isEmpty) return;

    setState(() => _shippingLoading = true);
    final totalWeight = _cart.items.fold<double>(
      0,
      (sum, item) => sum + item.totalWeight,
    );

    final result = city.isNotEmpty
        ? ShippingCalculator.calculateFromCity(city, totalWeight)
        : ShippingCalculator.calculate(address, totalWeight);

    if (!mounted) return;
    setState(() {
      _shippingResult = result;
      _shippingLoading = false;
      if (result.options.isNotEmpty) _selectedCourierIndex = 0;
    });
  }

  // ============================================================
  // ORDER PROCESSING
  // ============================================================
  Future<void> _processOrder() async {
    if (_selectedCourier == null) {
      _showToast(Translations.of('select_courier_first', context));
      return;
    }

    if (_selectedPaymentMethod == PaymentMethod.wallet &&
        _walletBalance < _grandTotal) {
      final result = await _showInsufficientBalanceDialog();
      if (result == true) {
        final topUpResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const TopUpScreen()),
        );
        if (topUpResult == true) setState(() {});
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
        actualShippingCost: courier.cost,
        voucherDiscount: _voucherValue,
        walletDiscount: _walletDiscount,
        paymentMethod: _selectedPaymentMethod,
        courier: courier.name,
        courierService: courier.service,
        estimatedDelivery: courier.etd,
      );
      _lastOrderId = orderId;

      if (_selectedPaymentMethod == PaymentMethod.wallet) {
        await HiveDb.instance.deductWallet(_grandTotal);
        await _orderRepo.confirmPayment(orderId);
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
      _showToast('Gagal memproses pesanan: $e', isError: true);
    }
  }

  // ============================================================
  // DIALOGS & TOASTS
  // ============================================================
  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.pitchBlack,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool?> _showInsufficientBalanceDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 30,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Translations.of('insufficient_balance', context),
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: 8),
            Text(
              '${Translations.of('your_balance_is', context)}'
              'Rp ${_formatRupiah(_walletBalance)}\n'
              '${Translations.of('top_up_first_to_continue', context)}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pitchBlack,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(Translations.of('top_up_now', context)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                Translations.of('change_payment_method', context),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrisPayment(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 120,
                  color: AppColors.pitchBlack,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Translations.of('scan_qris', context),
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: 8),
            Text(
              Translations.of('scan_qr_to_pay', context),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(Translations.of('already_paid', context)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cart.clearCart();
                widget.onBack();
              },
              child: Text(
                Translations.of('pay_later', context),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Translations.of('order_success_title', context),
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: 8),
            Text(
              Translations.of('thank_you_shopping', context),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    Translations.of('order_status', context),
                    style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey),
                  ),
                  Text(
                    _selectedPaymentMethod == PaymentMethod.wallet
                        ? Translations.of('payment_successful', context)
                        : Translations.of('waiting_confirmation', context),
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
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
                widget.onOrderSuccess(_lastOrderId ?? '');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pitchBlack,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(Translations.of('view_order', context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
            child: Text(
              Translations.of('back_to_home', context),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryAddress(),
                  const SizedBox(height: 12),
                  _buildCourierSection(),
                  const SizedBox(height: 12),
                  _buildPaymentMethod(),
                  if (_selectedPaymentMethod == PaymentMethod.wallet) ...[
                    const SizedBox(height: 12),
                    _buildWalletInfo(),
                  ],
                  const SizedBox(height: 12),
                  if (_availableVouchers.isNotEmpty) _buildVoucherSection(),
                  const SizedBox(height: 12),
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

  // ============================================================
  // APP BAR
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.pureWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.pitchBlack,
          size: 18,
        ),
        onPressed: widget.onBack,
      ),
      title: Text(
        Translations.of('checkout', context),
        style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================
  Widget _buildSectionCard({required Widget child, String? title}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.pitchBlack.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  // ============================================================
  // DELIVERY ADDRESS
  // ============================================================
  Widget _buildDeliveryAddress() {
    final address = HiveDb.instance.getUserAddress();
    final city = HiveDb.instance.getUserCity();
    final province = HiveDb.instance.getUserProvince();
    final phone = HiveDb.instance.getUserPhone();
    final session = HiveDb.instance.getUserSession();
    final name = session?['name'] as String? ?? 'Customer';

    return _buildSectionCard(
      title: Translations.of('shipping_address', context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.pitchBlack,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelLarge,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: AppTextStyles.caption,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  address,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey),
                ),
                if (city.isNotEmpty || province.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${city.isNotEmpty ? city : ''}${city.isNotEmpty && province.isNotEmpty ? ', ' : ''}${province.isNotEmpty ? province : ''}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COURIER SECTION
  // ============================================================
  Widget _buildCourierSection() {
    return _buildSectionCard(
      title: Translations.of('courier_shipping', context),
      child: _shippingLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : _shippingResult == null || _shippingResult!.options.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                Translations.of('address_not_recognized', context),
                style: AppTextStyles.caption,
              ),
            )
          : Column(
              children: [
                if (_shippingResult!.estimatedDistanceKm > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route_outlined,
                          size: 14,
                          color: AppColors.softGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Translations.of('distance_estimate', context).replaceAll('%s', '${_shippingResult!.estimatedDistanceKm}'),
                          style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey),
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.pitchBlack.withValues(alpha: 0.05)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.pitchBlack
                              : AppColors.borderGrey,
                          width: isSelected ? 2 : 1,
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
                                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: isSelected ? AppColors.pitchBlack : AppColors.darkGrey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Translations.of('eta_estimate', context).replaceAll('%s', opt.etd),
                                  style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CartRepository.formatPrice(opt.cost),
                            style: AppTextStyles.priceTextSmall.copyWith(fontWeight: FontWeight.w700, color: isSelected ? AppColors.pitchBlack : AppColors.darkGrey),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.pitchBlack,
                            ),
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

  // ============================================================
  // PAYMENT METHOD
  // ============================================================
  Widget _buildPaymentMethod() {
    return _buildSectionCard(
      title: Translations.of('payment_method', context),
      child: Row(
        children: List.generate(_paymentMethods.length, (index) {
          final method = _paymentMethods[index];
          final isSelected = index == _selectedPaymentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedPaymentIndex = index;
                if (_selectedPaymentMethod == PaymentMethod.cod) {
                  _useVoucher = false;
                }
              }),
              child: Container(
                margin: EdgeInsets.only(
                  right: index < _paymentMethods.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pitchBlack.withValues(alpha: 0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.pitchBlack
                        : AppColors.borderGrey,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      method['icon'],
                      size: 18,
                      color: isSelected
                          ? AppColors.pitchBlack
                          : AppColors.softGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      method['name'],
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? AppColors.pitchBlack : AppColors.darkGrey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // WALLET INFO
  // ============================================================
  Widget _buildWalletInfo() {
    final isInsufficient = _walletBalance < _grandTotal;

    return _buildSectionCard(
      title: Translations.of('digital_wallet_rc', context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.of('available_balance', context),
                      style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_formatRupiah(_walletBalance)}',
                      style: AppTextStyles.priceText,
                    ),
                  ],
                ),
              ),
              if (isInsufficient)
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pitchBlack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Translations.of('top_up', context),
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.pureWhite),
                    ),
                  ),
                ),
            ],
          ),
          if (_walletDiscount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.discount_outlined,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Translations.of('wallet_discount', context).replaceAll('%s', CartRepository.formatPrice(_walletDiscount)),
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isInsufficient) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Translations.of('balance_insufficient_topup', context),
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
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

  // ============================================================
  // VOUCHER SECTION
  // ============================================================
  Widget _buildVoucherSection() {
    if (_availableVouchers.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: Translations.of('discount_voucher', context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_availableVouchers.length, (index) {
            final v = _availableVouchers[index];
            final isSelected = _selectedVoucher?['id'] == v['id'];
            final percent = (v['discountPercent'] as num).toDouble();
            final discountValue = (_cart.subtotal * percent / 100).clamp(
              0,
              double.infinity,
            );

            return GestureDetector(
              onTap: () {
                if (_canUseVoucher) {
                  setState(() {
                    if (isSelected && _useVoucher) {
                      _selectedVoucher = null;
                      _useVoucher = false;
                    } else {
                      _selectedVoucher = v;
                      _useVoucher = true;
                    }
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected && _useVoucher
                      ? AppColors.pitchBlack.withValues(alpha: 0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected && _useVoucher
                        ? AppColors.pitchBlack
                        : AppColors.borderGrey,
                    width: isSelected && _useVoucher ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.pitchBlack,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.confirmation_num,
                        color: AppColors.pureWhite,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v['name'] as String? ?? '',
                            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: _canUseVoucher ? AppColors.pitchBlack : AppColors.softGrey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Diskon ${percent.toStringAsFixed(0)}% (s.d. ${CartRepository.formatPrice(discountValue as double)})',
                            style: AppTextStyles.bodyXSmall.copyWith(color: _canUseVoucher ? AppColors.darkGrey : AppColors.softGrey),
                          ),
                        ],
                      ),
                    ),
                    if (_canUseVoucher && isSelected && _useVoucher)
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.pitchBlack,
                      )
                    else if (_canUseVoucher && !isSelected)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                      )
                    else
                      const Icon(
                        Icons.lock_outline,
                        color: AppColors.softGrey,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }),
          if (_selectedVoucher != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 12,
                  color: AppColors.softGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  _canUseVoucher
                      ? Translations.of('voucher_will_apply', context)
                      : Translations.of('not_available_cod', context),
                  style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ORDER SUMMARY
  // ============================================================
  Widget _buildOrderSummary() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translations.of('order_summary', context),
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 10),
          ..._cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ProductImage(
                        imageUrl: item.imageUrl,
                        width: 44,
                        height: 44,
                        borderRadius: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.pitchBlack),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.selectedSize} • x${item.quantity}',
                          style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey),
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
          const Divider(height: 12),
          _buildSummaryRow(
            'Subtotal',
            CartRepository.formatPrice(_cart.subtotal),
          ),
          const SizedBox(height: 4),
          _buildSummaryRow(
            Translations.of('shipping', context),
            _shippingCost == 0
                ? Translations.of('free', context)
                : CartRepository.formatPrice(_shippingCost),
            valueColor: _shippingCost == 0 ? Colors.green : null,
          ),
          if (_voucherValue > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'Diskon Voucher',
              '-${CartRepository.formatPrice(_voucherValue)}',
              valueColor: Colors.green,
            ),
          ],
          if (_walletDiscount > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'Diskon Dompet',
              '-${CartRepository.formatPrice(_walletDiscount)}',
              valueColor: Colors.green,
            ),
          ],
          const Divider(height: 12),
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
          style: isBold ? AppTextStyles.priceTextSmall.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey),
        ),
        Text(
          value,
          style: isBold ? AppTextStyles.priceTextSmall.copyWith(fontWeight: FontWeight.w700, color: valueColor ?? AppColors.pitchBlack) : AppTextStyles.labelMedium.copyWith(color: valueColor ?? AppColors.darkGrey),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.pitchBlack.withValues(alpha: 0.05),
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
                Text(
                  Translations.of('total_payment', context),
                  style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey),
                ),
                Text(
                  CartRepository.formatPrice(_grandTotal),
                  style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pitchBlack,
                  foregroundColor: AppColors.pureWhite,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.pureWhite,
                        ),
                      )
                    : Text(
                        _selectedPaymentMethod == PaymentMethod.wallet
                            ? Translations.of('pay_with_wallet', context)
                            : Translations.of('place_order', context),
                        style: AppTextStyles.buttonText,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

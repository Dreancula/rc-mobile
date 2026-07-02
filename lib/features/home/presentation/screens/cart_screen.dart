import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/translations.dart';
import '../../data/repositories/cart_repository.dart';
import '../widgets/cart_item_card.dart';

/// Cart Screen - Display all items in shopping cart
class CartScreen extends StatefulWidget {
  final VoidCallback onCheckout;
  final VoidCallback onContinueShopping;
  final Function(String) onProductTap;

  const CartScreen({
    super.key,
    required this.onCheckout,
    required this.onContinueShopping,
    required this.onProductTap,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartRepository _cart = CartRepository();

  @override
  void initState() {
    super.initState();
    // Refresh state when screen is shown
    setState(() {});
  }

  void _refreshCart() {
    setState(() {});
  }

  void _showRemoveConfirmation(String itemId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        title: Text(Translations.of('remove_item', context)),
        content: Text('${Translations.of('remove_item_confirm', context)} "$itemName"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.of('cancel', context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cart.removeItem(itemId);
              _refreshCart();
            },
            child: Text(
              Translations.of('delete', context),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: _buildAppBar(),
      body: _cart.isEmpty ? _buildEmptyCart() : _buildCartContent(),
      bottomSheet: _cart.isEmpty ? null : _buildBottomSheet(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlack),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(Translations.of('shopping_cart', context), style: AppTextStyles.heading4),
          if (!_cart.isEmpty)
            Text(
              '${_cart.itemCount} ${Translations.of('items_count', context)}',
              style: AppTextStyles.caption,
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (!_cart.isEmpty)
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  title: Text(Translations.of('clear_cart', context)),
                  content: Text(Translations.of('clear_cart_confirm', context)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(Translations.of('cancel', context)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cart.clearCart();
                        _refreshCart();
                      },
                      child: Text(
                        Translations.of('clear_all', context),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(Translations.of('clear_all', context)),
          ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 60,
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              Translations.of('empty_cart', context),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              Translations.of('no_products_added', context),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXL),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: widget.onContinueShopping,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                    vertical: AppConstants.spacingM,
                  ),
                ),
                child: Text(Translations.of('start_shopping', context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return ListView(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingM,
        right: AppConstants.spacingM,
        top: AppConstants.spacingM,
        bottom: 160,
      ),
      children: [
        _buildShippingProgress(),
        ..._cart.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CartItemCard(
            item: item,
            onIncrement: () {
              _cart.incrementQuantity(item.id);
              _refreshCart();
            },
            onDecrement: () {
              _cart.decrementQuantity(item.id);
              _refreshCart();
            },
            onRemove: () {
              _showRemoveConfirmation(item.id, item.name);
            },
            onTap: () => widget.onProductTap(item.productId),
          ),
        )),
      ],
    );
  }

  Widget _buildShippingProgress() {
    final subtotal = _cart.subtotal;
    final freeShippingThreshold = 500000.0;
    final progress = (subtotal / freeShippingThreshold).clamp(0.0, 1.0);
    final remaining = freeShippingThreshold - subtotal;

    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlack.withValues(alpha: 0.05),
            AppColors.primaryBlack.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: subtotal >= freeShippingThreshold
                    ? AppColors.success
                    : AppColors.primaryBlack,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  subtotal >= freeShippingThreshold
                      ? Translations.of('free_shipping_earned', context)
                      : Translations.of('remaining_for_free_shipping', context).replaceAll('%s', CartRepository.formatPrice(remaining)),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderGrey,
              valueColor: AlwaysStoppedAnimation<Color>(
                subtotal >= freeShippingThreshold
                    ? AppColors.success
                    : AppColors.primaryBlack,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            _buildSummaryRow('Subtotal', CartRepository.formatPrice(_cart.subtotal)),
            const Divider(height: AppConstants.spacingL),
            _buildSummaryRow(
              'Total',
              CartRepository.formatPrice(_cart.subtotal),
              isTotal: true,
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Checkout Button
            Container(
              width: double.infinity,
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
                onPressed: widget.onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(Translations.of('checkout', context), style: AppTextStyles.buttonText),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? subtitleColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? AppTextStyles.heading4 : AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.heading4
              : AppTextStyles.priceTextSmall.copyWith(
                  color: subtitleColor ?? AppColors.primaryBlack,
                ),
        ),
      ],
    );
  }
}

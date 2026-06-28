import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/models/cart_model.dart';
import '../../data/repositories/cart_repository.dart';

/// Cart Item Card Widget
class CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: _buildDismissBackground(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              _buildProductImage(),
              const SizedBox(width: AppConstants.spacingM),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      item.name,
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),

                    // Variant
                    Text(
                      '${item.selectedSize} • ${item.weight} gr',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppConstants.spacingS),

                    // Price
                    Text(
                      CartRepository.formatPrice(item.price),
                      style: AppTextStyles.priceTextSmall,
                    ),
                    const SizedBox(height: AppConstants.spacingM),

                    // Quantity & Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity Controls
                        _buildQuantityControls(),

                        // Total Price
                        Text(
                          CartRepository.formatPrice(item.totalPrice),
                          style: AppTextStyles.priceText.copyWith(
                            color: AppColors.primaryBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return ProductImage(
      imageUrl: item.imageUrl,
      width: 90,
      height: 110,
      borderRadius: AppConstants.radiusM,
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${item.quantity}',
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.center,
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        child: Icon(icon, size: 16, color: AppColors.primaryBlack),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppConstants.spacingL),
      child: const Icon(
        Icons.delete_outline,
        color: AppColors.primaryWhite,
        size: 28,
      ),
    );
  }
}

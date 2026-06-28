import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/product_model.dart';
import 'product_card.dart';

/// Product Grid Widget with Responsive Layout
class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductTap;
  final Function(ProductModel) onFavoriteTap;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.gridCrossAxisCount,
        childAspectRatio: AppConstants.gridChildAspectRatio,
        crossAxisSpacing: AppConstants.gridSpacing,
        mainAxisSpacing: AppConstants.gridSpacing,
      ),
      itemCount: products.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => onProductTap(product),
          onFavoriteTap: () => onFavoriteTap(product),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.softGrey,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Tidak ada produk',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Produk untuk kategori ini belum tersedia',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

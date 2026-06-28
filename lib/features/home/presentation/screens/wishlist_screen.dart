import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../data/repositories/cart_repository.dart';
import '../../domain/models/product_model.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<ProductModel> _wishlist = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  void _loadWishlist() {
    setState(() {
      _wishlist = HiveDb.instance
          .getActiveProducts()
          .where((p) => p.isFavorite)
          .toList();
    });
  }

  void _toggleFavorite(ProductModel product) {
    final updated = product.copyWith(isFavorite: false);
    HiveDb.instance.saveProduct(updated);
    _loadWishlist();
  }

  void _addToCart(ProductModel product) {
    final size = product.availableSizes.isNotEmpty
        ? product.availableSizes.first
        : 'M';
    try {
      CartRepository().addItem(product: product, selectedSize: size);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} ditambahkan ke keranjang'),
          backgroundColor: AppColors.primaryBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Wishlist', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: _wishlist.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppColors.softGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Wishlist Kosong',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.softGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan produk favoritmu',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: _wishlist.length,
              itemBuilder: (context, index) {
                final product = _wishlist[index];
                return _buildWishlistItem(product);
              },
            ),
    );
  }

  Widget _buildWishlistItem(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: product,
              onAddToCart: () => Navigator.pop(context),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ProductImage(
                imageUrl: product.imageUrl,
                width: 80,
                height: 80,
                borderRadius: AppConstants.radiusS,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CartRepository.formatPrice(product.price),
                      style: AppTextStyles.priceTextSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _toggleFavorite(product),
                    icon: const Icon(Icons.favorite, color: AppColors.error),
                    iconSize: 22,
                  ),
                  IconButton(
                    onPressed: product.stock > 0 ? () => _addToCart(product) : null,
                    icon: Icon(
                      Icons.add_shopping_cart,
                      color: product.stock > 0 ? AppColors.primaryBlack : AppColors.softGrey,
                    ),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

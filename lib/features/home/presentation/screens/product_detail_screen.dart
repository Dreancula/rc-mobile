import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/models/product_model.dart';
import '../../data/repositories/cart_repository.dart';

/// Product Detail Screen - Full product information with add to cart
class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedSizeIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;

  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
  }

  void _incrementQuantity() {
    if (_quantity < widget.product.stock) {
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _toggleFavorite() {
    final updated = widget.product.copyWith(isFavorite: !_isFavorite);
    HiveDb.instance.saveProduct(updated);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _addToCart() {
    final cart = CartRepository();
    try {
      cart.addItem(
        product: widget.product,
        selectedSize: _sizes[_selectedSizeIndex],
        quantity: _quantity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primaryWhite, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${widget.product.name} ditambahkan ke keranjang'),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: AppColors.primaryWhite,
            onPressed: widget.onAddToCart,
          ),
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
      backgroundColor: AppColors.primaryWhite,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildSliverAppBar(),

          // Product Info
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryWhite,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusXL),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Rating
                    _buildCategoryAndRating(),
                    const SizedBox(height: AppConstants.spacingM),

                    // Product Name
                    Text(
                      widget.product.name,
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: AppConstants.spacingS),

                    // Price
                    Text(
                      CartRepository.formatPrice(widget.product.price),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingM),

                    // Stock & Weight badges
                    Row(
                      children: [
                        _buildBadge(
                          icon: Icons.inventory_2_outlined,
                          text: 'Stok: ${widget.product.stock}',
                          color: widget.product.stock <= 5
                              ? AppColors.error
                              : null,
                        ),
                        if (widget.product.stock <= 5)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Hanya tersisa ${widget.product.stock}!',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: AppConstants.spacingM),
                        _buildBadge(
                          icon: Icons.fitness_center_outlined,
                          text: '${widget.product.weight} gr',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingL),

                    // Size Selection
                    _buildSizeSelector(),
                    const SizedBox(height: AppConstants.spacingL),

                    // Quantity Selector
                    _buildQuantitySelector(),
                    const SizedBox(height: AppConstants.spacingL),

                    // Description
                    _buildDescription(),
                    const SizedBox(height: AppConstants.spacingL),

                    // Reviews Summary
                    _buildReviewsSummary(),

                    const SizedBox(height: 100), // Bottom padding for button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppColors.primaryWhite,
      leading: _buildBackButton(),
      actions: [
        _buildActionButton(Icons.share_outlined),
        _buildActionButton(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          onTap: _toggleFavorite,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ProductImage(
              imageUrl: widget.product.imageUrl,
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primaryWhite.withValues(alpha: 0.8),
                      AppColors.primaryWhite,
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

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.primaryBlack,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: icon == Icons.favorite ? AppColors.error : AppColors.primaryBlack,
        onPressed: onTap ?? () {},
      ),
    );
  }

  Widget _buildCategoryAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
            widget.product.category,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.darkGrey,
            ),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${widget.product.rating}',
              style: AppTextStyles.labelLarge,
            ),
            Text(
              ' (${widget.product.reviewCount} reviews)',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ukuran', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppConstants.spacingS),
        Row(
          children: List.generate(_sizes.length, (index) {
            final isSelected = index == _selectedSizeIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedSizeIndex = index),
              child: AnimatedContainer(
                duration: AppConstants.animationFast,
                margin: const EdgeInsets.only(right: AppConstants.spacingS),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlack : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlack : AppColors.borderGrey,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _sizes[index],
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected ? AppColors.primaryWhite : AppColors.darkGrey,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBadge({required IconData icon, required String text, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.lightGrey).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.darkGrey),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color ?? AppColors.darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jumlah', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppConstants.spacingS),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: _decrementQuantity,
                enabled: _quantity > 1,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                ),
                child: Text(
                  '$_quantity',
                  style: AppTextStyles.heading4,
                  textAlign: TextAlign.center,
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: _incrementQuantity,
                enabled: _quantity < widget.product.stock,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.primaryBlack : AppColors.softGrey,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deskripsi', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          widget.product.description.isNotEmpty
              ? widget.product.description
              : 'Produk ini terbuat dari bahan cotton premium yang nyaman dan adem saat dipakai. Cocok untuk aktivitas sehari-hari maupun acara casual. Dengan desain yang minimalis dan modern, produk ini mudah dipadukan dengan berbagai outfit.',
          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildInfoRow(Icons.verified, '100% Original'),
        _buildInfoRow(Icons.local_shipping_outlined, 'Gratis ongkir min. Rp 500.000'),
        _buildInfoRow(Icons.autorenew, '30 hari pengembalian'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.darkGrey),
          const SizedBox(width: AppConstants.spacingS),
          Text(text, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildReviewsSummary() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppColors.primaryWhite,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.product.rating}',
                  style: AppTextStyles.heading2,
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.product.rating.floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating Produk',
                  style: AppTextStyles.labelLarge,
                ),
                Text(
                  'Based on ${widget.product.reviewCount} reviews',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Lihat Semua'),
          ),
        ],
      ),
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
                Text('Total', style: AppTextStyles.caption),
                Text(
                  CartRepository.formatPrice(widget.product.price * _quantity),
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
                child: ElevatedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.primaryWhite),
                  label: Text('Tambah ke Keranjang', style: AppTextStyles.buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
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

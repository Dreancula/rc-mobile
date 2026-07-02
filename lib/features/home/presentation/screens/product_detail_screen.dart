import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/models/product_model.dart';
import '../../data/repositories/cart_repository.dart';


class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onAddToCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onCartTap;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.onBuyNow,
    this.onCartTap,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedSizeIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;
  late List<String> _sizes;
  bool _isLoading = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
    _sizes = widget.product.availableSizes.toList();
    if (_sizes.isEmpty) _sizes = ['M']; // fallback
  }

  ProductModel get _product => widget.product;

  void _incrementQuantity() {
    final selectedSize = _sizes[_selectedSizeIndex];
    final maxStock = _product.stockForSize(selectedSize);
    if (_quantity < maxStock) {
      setState(() => _quantity++);
    } else {
      _showToast('Stok tersisa $maxStock');
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _toggleFavorite() {
    final updated = _product.copyWith(isFavorite: !_isFavorite);
    HiveDb.instance.saveProduct(updated);
    setState(() => _isFavorite = !_isFavorite);
    _showToast(_isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit');
  }

  void _addToCart() {
    if (_isLoading) return;

    final cart = CartRepository();
    try {
      setState(() => _isLoading = true);

      cart.addItem(
        product: _product,
        selectedSize: _sizes[_selectedSizeIndex],
        quantity: _quantity,
      );

      _showToast('${_product.name} ditambahkan ke keranjang', isSuccess: true);

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _isLoading = false);
        widget.onAddToCart();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast(e.toString(), isSuccess: false);
    }
  }

  void _buyNow() {
    if (_isLoading) return;

    final cart = CartRepository();
    try {
      setState(() => _isLoading = true);

      cart.addItem(
        product: _product,
        selectedSize: _sizes[_selectedSizeIndex],
        quantity: _quantity,
      );

      _showToast('${_product.name} ditambahkan ke keranjang', isSuccess: true);

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _isLoading = false);
        widget.onBuyNow?.call();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast(e.toString(), isSuccess: false);
    }
  }

  void _showToast(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: AppColors.pureWhite,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.primaryBlack : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryAndRating(),
                    const SizedBox(height: 12),
                    Text(
                      _product.name,
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CartRepository.formatPrice(_product.price),
                      style: AppTextStyles.priceTextLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildBadges(),
                    const SizedBox(height: 16),
                    if (_sizes.isNotEmpty) _buildSizeSelector(),
                    const SizedBox(height: 16),
                    _buildQuantitySelector(),
                    const SizedBox(height: 16),
                    _buildDescription(),
                    const SizedBox(height: 16),
                    _buildReviewsSummary(),
                    const SizedBox(height: 100),
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

  // ===== SLIVER APP BAR =====
  Widget _buildSliverAppBar() {
    final images = _product.images;
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: AppColors.pureWhite,
      leading: _buildCircleButton(
        Icons.arrow_back_ios_new,
        onTap: () => Navigator.pop(context),
      ),
      actions: [
        _buildCircleButton(
          Icons.shopping_bag_outlined,
          onTap: () => widget.onCartTap?.call(),
          badgeCount: CartRepository().itemCount,
        ),
        _buildCircleButton(
          Icons.share_outlined,
          onTap: () => _showToast('Fitur share segera hadir'),
        ),
        _buildCircleButton(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          onTap: _toggleFavorite,
          color: _isFavorite ? AppColors.error : null,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (images.length > 1)
              PageView.builder(
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                itemBuilder: (context, index) => ProductImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                ),
              )
            else
              ProductImage(imageUrl: _product.imageUrl, fit: BoxFit.cover),
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? AppColors.pureWhite
                            : AppColors.pureWhite.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(
    IconData icon, {
    VoidCallback? onTap,
    Color? color,
    int? badgeCount,
  }) {
    final button = Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.pitchBlack.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color ?? AppColors.pitchBlack,
        onPressed: onTap ?? () {},
        padding: const EdgeInsets.all(8),
      ),
    );

    if (badgeCount != null && badgeCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return button;
  }

  // ===== CATEGORY & RATING =====
  Widget _buildCategoryAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _product.category,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              _product.rating.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_product.reviewCount})',
              style: AppTextStyles.bodyXSmall.copyWith(
                color: AppColors.softGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===== BADGES =====
  Widget _buildBadges() {
    final isLowStock = _product.stock <= 5;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _badge(
          icon: Icons.inventory_2_outlined,
          text: 'Stok: ${_product.stock}',
          color: isLowStock ? AppColors.error : AppColors.darkGrey,
        ),
        if (isLowStock)
          _badge(
            icon: Icons.warning_amber_rounded,
            text: 'Hanya tersisa ${_product.stock}!',
            color: AppColors.error,
          ),
        _badge(
          icon: Icons.fitness_center_outlined,
          text: '${_product.weight} gr',
        ),
        _badge(
          icon: Icons.verified_outlined,
          text: '100% Original',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _badge({required IconData icon, required String text, Color? color}) {
    final badgeColor = color ?? AppColors.darkGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodyXSmall.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===== SIZE SELECTOR =====
  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ukuran',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.pitchBlack,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_sizes.length, (index) {
            final isSelected = index == _selectedSizeIndex;
            final size = _sizes[index];
            final sizeStock = _product.stockForSize(size);
            final isAvailable = sizeStock > 0;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedSizeIndex = index;
                        _quantity = 1;
                      });
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pitchBlack
                      : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.pitchBlack
                        : (isAvailable
                              ? AppColors.borderGrey
                              : AppColors.borderGrey.withValues(alpha: 0.3)),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.pitchBlack.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      size,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isSelected
                            ? AppColors.pureWhite
                            : (isAvailable
                                  ? AppColors.pitchBlack
                                  : AppColors.softGrey),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable ? 'Sisa $sizeStock' : 'Habis',
                      style: AppTextStyles.bodyXSmall.copyWith(
                        color: isSelected
                            ? AppColors.pureWhite.withValues(alpha: 0.6)
                            : AppColors.softGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ===== QUANTITY SELECTOR =====
  Widget _buildQuantitySelector() {
    final maxStock = _product.stockForSize(_sizes[_selectedSizeIndex]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.pitchBlack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _quantityButton(
                icon: Icons.remove,
                onTap: _decrementQuantity,
                enabled: _quantity > 1,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$_quantity',
                  style: AppTextStyles.priceText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              _quantityButton(
                icon: Icons.add,
                onTap: _incrementQuantity,
                enabled: _quantity < maxStock,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.pureWhite : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.pitchBlack : AppColors.softGrey,
          size: 18,
        ),
      ),
    );
  }

  // ===== DESCRIPTION =====
  Widget _buildDescription() {
    final desc = _product.description.isNotEmpty
        ? _product.description
        : 'Produk berkualitas tinggi dengan desain modern dan nyaman dipakai.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.pitchBlack,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _infoRow(Icons.verified_outlined, 'Original'),
            _infoRow(Icons.local_shipping_outlined, 'Gratis Ongkir'),
            _infoRow(Icons.thumb_up_outlined, 'Garansi Uang Kembali 30%'),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.darkGrey),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodyXSmall.copyWith(
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }

  // ===== REVIEWS SUMMARY =====
  Widget _buildReviewsSummary() {
    final hasReviews = _product.reviewCount > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _product.rating.toString(),
                  style: AppTextStyles.priceTextLarge,
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < _product.rating.floor()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating Produk',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hasReviews
                      ? '${_product.reviewCount} ulasan'
                      : 'Belum ada ulasan',
                  style: AppTextStyles.bodyXSmall.copyWith(
                    color: AppColors.softGrey,
                  ),
                ),
              ],
            ),
          ),
          if (hasReviews)
            TextButton(
              onPressed: _showAllReviews,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lihat', style: AppTextStyles.labelMedium),
                  Icon(Icons.arrow_forward_ios, size: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAllReviews() {
    final reviews = HiveDb.instance.getProductReviews(_product.id);
    if (reviews.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ulasan (${reviews.length})',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) =>
                    _buildReviewItem(reviews[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = (review['rating'] as num).toInt();
    final userName = review['userName'] as String? ?? 'User';
    final comment = review['comment'] as String? ?? '';
    final photos = (review['photos'] as List?)?.cast<String>() ?? <String>[];
    final adminReply = review['adminReply'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.pitchBlack,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment, style: AppTextStyles.bodySmall),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photos[i]),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.lightGrey,
                        child: const Icon(Icons.image_not_supported, size: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (adminReply != null && adminReply.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pitchBlack.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply, size: 14, color: AppColors.softGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balasan Admin',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.softGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(adminReply, style: AppTextStyles.bodySmall),
                      ],
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

  // ===== BOTTOM BAR =====
  Widget _buildBottomBar() {
    final total = _product.price * _quantity;
    final isAvailable = _product.stockForSize(_sizes[_selectedSizeIndex]) > 0;
    final hasBuyNow = widget.onBuyNow != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.pitchBlack.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: AppTextStyles.bodyXSmall.copyWith(
                          color: AppColors.softGrey,
                        ),
                      ),
                      Text(
                        CartRepository.formatPrice(total),
                        style: AppTextStyles.heading4.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  if (hasBuyNow) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isAvailable ? _addToCart : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isAvailable
                              ? AppColors.pitchBlack
                              : AppColors.softGrey,
                          side: BorderSide(
                            color: isAvailable
                                ? AppColors.pitchBlack
                                : AppColors.softGrey,
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isAvailable
                              ? Translations.of('add_to_cart', context)
                              : 'Stok Habis',
                          style: AppTextStyles.labelLarge,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAvailable ? _buyNow : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable
                              ? AppColors.pitchBlack
                              : AppColors.softGrey,
                          foregroundColor: AppColors.pureWhite,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isAvailable
                              ? Translations.of('buy_now', context)
                              : 'Stok Habis',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAvailable ? _addToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable
                              ? AppColors.pitchBlack
                              : AppColors.softGrey,
                          foregroundColor: AppColors.pureWhite,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAvailable
                                  ? Icons.shopping_bag_outlined
                                  : Icons.block,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAvailable
                                  ? Translations.of('add_to_cart', context)
                                  : 'Stok Habis',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

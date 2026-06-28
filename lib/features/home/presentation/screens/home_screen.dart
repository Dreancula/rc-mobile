import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_icons.dart';
import '../../../../core/widgets/product_image.dart';
import '../../data/repositories/cart_repository.dart';
import '../../domain/models/product_model.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'chat_screen.dart';
import 'category_screen.dart';
import 'top_up_screen.dart';

/// Home Screen - Clean Modern & Elegant Monochrome Design
class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;
  final Function(ProductModel)? onProductTap;

  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onCartTap,
    this.onProductTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveDb _db = HiveDb.instance;
  String _selectedCategory = 'All';
  List<ProductModel> _products = [];
  final List<ProductModel> _favoriteProducts = [];
  final CartRepository _cartRepository = CartRepository();
  int _cartItemCount = 0;

  static const Map<String, IconData> _categoryIcons = {
    'All': Icons.grid_view_rounded,
    'T-Shirt': Icons.checkroom_outlined,
    'Shirt': Icons.dry_cleaning_outlined,
    'Pants': Icons.straighten_outlined,
    'Jacket': Icons.layers_outlined,
    'Accessories': Icons.watch_outlined,
  };

  List<String> get _categories {
    final cats = _db.getCategories().map((c) => c.name).toList();
    cats.insert(0, 'All');
    return cats;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _updateCartCount();
  }

  void _loadProducts() {
    setState(() {
      final activeProducts = _db.getActiveProducts();
      if (_selectedCategory == 'All') {
        _products = activeProducts;
      } else {
        _products = activeProducts
            .where((p) => p.category == _selectedCategory)
            .toList();
      }
    });
  }

  void _updateCartCount() {
    setState(() {
      _cartItemCount = _cartRepository.itemCount;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _loadProducts();
    });
  }

  void _onProductTap(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product,
          onAddToCart: () {
            _updateCartCount();
            _navigateToCart();
          },
        ),
      ),
    ).then((_) => _updateCartCount());
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          onProductTap: _onProductTap,
        ),
      ),
    );
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CartScreen(
            onCheckout: _navigateToCheckout,
            onContinueShopping: () => Navigator.pop(context),
            onProductTap: (productId) {
              final product = _db.getProductById(productId) ?? _products.first;
              _onProductTap(product);
            },
          ),
      ),
    ).then((_) => _updateCartCount());
  }

  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          onOrderSuccess: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _onFavoriteTap(ProductModel product) {
    final updated = product.copyWith(isFavorite: !product.isFavorite);
    setState(() {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updated;
      }
      if (updated.isFavorite) {
        _favoriteProducts.add(updated);
      } else {
        _favoriteProducts.removeWhere((p) => p.id == product.id);
      }
    });
    _db.saveProduct(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ===== STICKY HEADER =====
            _buildHeader(),
            // ===== SCROLLABLE CONTENT =====
            Expanded(
              child: RefreshIndicator(
                color: AppColors.pitchBlack,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                  _loadProducts();
                  _updateCartCount();
                },
                child: CustomScrollView(
                  slivers: [
                    // ===== DOMPET DIGITAL SECTION =====
                    SliverToBoxAdapter(
                      child: _buildDompetCard(),
                    ),

                    // ===== CATEGORIES SECTION =====
                    const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spacingL)),
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'Kategori',
                        onViewAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CategoryScreen()),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildCategories(),
                    ),

                    // ===== PRODUCTS SECTION =====
                    const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spacingL)),
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: _selectedCategory == 'All'
                            ? 'Produk'
                            : _selectedCategory,
                        onViewAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CategoryScreen()),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildProductGrid(),
                    ),

                    // Bottom Padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppConstants.spacingXXL),
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

  // ===== HEADER WIDGET =====
  Widget _buildHeader() {
    final userName = _db.getUserSession()?['name'] ?? 'User';
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderGrey),
        ),
      ),
      child: Row(
        children: [
          // Greeting Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Hey, ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pitchBlack,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: userName,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.pitchBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  'Discover your style',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.softGrey,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Row
          Row(
            children: [
              // Search Button
              SquircleIconButton(
                icon: Icons.search_rounded,
                onTap: _navigateToSearch,
              ),
              const SizedBox(width: AppConstants.spacingS),

              // Chat Button
              SquircleIconButton(
                icon: Icons.chat_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
              ),
              const SizedBox(width: AppConstants.spacingS),

              // Cart Button with Badge
              SquircleIconButton(
                icon: Icons.shopping_bag_outlined,
                onTap: _navigateToCart,
                badgeCount: _cartItemCount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== DOMPET DIGITAL CARD =====
  Widget _buildDompetCard() {
    final balance = _db.getWalletBalance();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingM,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          gradient: AppColors.blackGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.pureWhite,
                    size: 22,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopUpScreen()),
                  ).then((_) => setState(() {})),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: AppColors.primaryBlack),
                        SizedBox(width: 4),
                        Text(
                          'Top Up',
                          style: TextStyle(
                            color: AppColors.primaryBlack,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Dompet Digital RC',
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Rp ${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== SECTION HEADER WIDGET =====
  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.pitchBlack,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== CATEGORIES WIDGET =====
  Widget _buildCategories() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppConstants.spacingM),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return _buildCategoryItem(category, isSelected);
        },
      ),
    );
  }

  Widget _buildCategoryItem(String category, bool isSelected) {
    final iconData = _categoryIcons[category] ?? Icons.category_outlined;

    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Squircle Icon Container
          AnimatedContainer(
            duration: AppConstants.animationFast,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.pitchBlack : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.pitchBlack : AppColors.borderGrey,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.pitchBlack.withValues(alpha: 0.15)
                      : AppColors.pitchBlack.withValues(alpha: 0.05),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              iconData,
              size: 28,
              color: isSelected ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),

          // Category Label
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.pitchBlack : AppColors.softGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ===== PRODUCT GRID WIDGET =====
  Widget _buildProductGrid() {
    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => _onProductTap(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.pitchBlack.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Rating Badge - Top Left
                  Positioned(
                    top: AppConstants.spacingS,
                    left: AppConstants.spacingS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.blackGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pitchBlack.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Favorite Button - Top Right
                  Positioned(
                    top: AppConstants.spacingS,
                    right: AppConstants.spacingS,
                    child: GestureDetector(
                      onTap: () => _onFavoriteTap(product),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pitchBlack.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          product.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.isFavorite
                              ? AppColors.error
                              : AppColors.softGrey,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pitchBlack,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Price
                    Text(
                      _formatPrice(product.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pitchBlack,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Review Count
                    Text(
                      '${product.reviewCount} reviews',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.softGrey,
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Tidak ada produk',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.charcoal,
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

  String _formatPrice(double price) => CartRepository.formatPrice(price);
}

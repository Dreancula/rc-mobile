import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_icons.dart';
import '../../../../core/widgets/product_image.dart';
import '../../data/repositories/cart_repository.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/category_model.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'chat_screen.dart';
import 'category_screen.dart';
import 'top_up_screen.dart';
import 'points_screen.dart';

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

  static const Map<String, IconData> _iconPathMap = {
    'tshirt': Icons.checkroom_outlined,
    'shirt': Icons.dry_cleaning_outlined,
    'pants': Icons.straighten,
    'hoodie': Icons.layers_outlined,
    'accessories': Icons.watch_outlined,
    'hat': Icons.watch_outlined,
    'jacket': Icons.layers_outlined,
  };

  static const Map<String, Color> _iconColorMap = {
    'tshirt': Color(0xFFE74C3C),
    'shirt': Color(0xFF3498DB),
    'pants': Color(0xFF2ECC71),
    'hoodie': Color(0xFFE67E22),
    'accessories': Color(0xFF9B59B6),
    'hat': Color(0xFF9B59B6),
    'jacket': Color(0xFFE67E22),
  };

  List<CategoryModel> get _categories {
    final cats = _db.getCategories();
    cats.insert(0, CategoryModel(id: 'all', name: 'All'));
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
        builder: (context) => SearchScreen(onProductTap: _onProductTap),
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
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildDompetCard(),
                          const SizedBox(height: AppConstants.spacingL),
                          _buildSectionHeader(
                            title: 'Kategori',
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CategoryScreen(),
                              ),
                            ),
                          ),
                          _buildCategories(),
                          const SizedBox(height: AppConstants.spacingL),
                          _buildSectionHeader(
                            title: _selectedCategory == 'All'
                                ? 'Produk'
                                : _selectedCategory,
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CategoryScreen(),
                              ),
                            ),
                          ),
                          _buildProductGrid(),
                          const SizedBox(height: AppConstants.spacingXXL),
                        ],
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

  // ===== HEADER =====
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
        border: Border(bottom: BorderSide(color: AppColors.borderGrey)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hey, ',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.pitchBlack,
                        ),
                      ),
                      TextSpan(
                        text: userName,
                        style: AppTextStyles.heading2.copyWith(
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
          Row(
            children: [
              SquircleIconButton(
                icon: Icons.search_rounded,
                onTap: _navigateToSearch,
              ),
              const SizedBox(width: AppConstants.spacingS),
              SquircleIconButton(
                icon: Icons.chat_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Consumer<NotificationService>(
                builder: (context, notifService, _) {
                  final count = notifService.unreadUserCount;
                  return SquircleIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(recipient: 'user'),
                      ),
                    ),
                    badgeCount: count > 0 ? count : null,
                  );
                },
              ),
              const SizedBox(width: AppConstants.spacingS),
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

  // ===== DOMPET CARD =====
  Widget _buildDompetCard() {
    final balance = _db.getWalletBalance();
    final points = _db.getPointsBalance();
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.primaryBlack,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Top Up',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primaryBlack,
                            fontWeight: FontWeight.w600,
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
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.pureWhite.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Rp ${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
              style: AppTextStyles.heading1.copyWith(
                fontSize: 28,
                color: AppColors.pureWhite,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PointsScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 18,
                      color: AppColors.pureWhite.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$points Poin',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.pureWhite.withValues(alpha: 0.6),
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

  // ===== SECTION HEADER =====
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
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppColors.blackGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.pitchBlack,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text(
                  'Lihat Semua',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: AppColors.charcoal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== CATEGORIES =====
  Widget _buildCategories() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        itemCount: _categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppConstants.spacingM),
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category.name == _selectedCategory;
            return _buildCategoryItem(category, isSelected);
          },
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category, bool isSelected) {
    final iconPath = category.iconPath ?? '';
    final iconData = _iconPathMap[iconPath] ?? Icons.category_outlined;
    final iconColor = _iconColorMap[iconPath] ?? AppColors.charcoal;

    return GestureDetector(
      onTap: () => _onCategorySelected(category.name),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.pitchBlack : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.pitchBlack : AppColors.borderGrey,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pitchBlack.withValues(
                    alpha: isSelected ? 0.12 : 0.04,
                  ),
                  blurRadius: isSelected ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              iconData,
              size: 26,
              color: isSelected ? AppColors.pureWhite : iconColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: AppTextStyles.caption.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.pitchBlack : AppColors.charcoal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===== PRODUCT GRID =====
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

  // ===== PRODUCT CARD =====
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
                  // Rating Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pitchBlack.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating}',
                            style: AppTextStyles.bodyXSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _onFavoriteTap(product),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pitchBlack.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          product.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: product.isFavorite
                              ? Colors.red.shade400
                              : AppColors.softGrey,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Stock Badge
                  if (product.stock <= 5 && product.stock > 0)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Stok Terbatas',
                          style: AppTextStyles.bodyXSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.pureWhite,
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.pitchBlack,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      _formatPrice(product.price),
                      style: AppTextStyles.priceTextSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.reviewCount > 0
                          ? '${product.reviewCount} ulasan'
                          : 'Baru',
                      style: AppTextStyles.bodyXSmall.copyWith(
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 35,
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Tidak ada produk',
              style: AppTextStyles.heading4.copyWith(color: AppColors.charcoal),
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

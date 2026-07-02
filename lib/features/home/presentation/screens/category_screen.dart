import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/models/product_model.dart';
import 'product_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _selectedCategoryIndex = 0;
  late List<String> _categories;
  final Map<String, List<ProductModel>> _categoryProducts = {};
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter states
  String _selectedSort = 'Terbaru';

  final List<String> _sortOptions = [
    'Terbaru',
    'Termurah',
    'Termahal',
    'Terpopuler',
  ];

  @override
  void initState() {
    super.initState();
    _categories = [
      'All',
      ...HiveDb.instance.getCategories().map((c) => c.name),
    ];
    _loadProducts();
  }

  void _loadProducts() {
    final allProducts = HiveDb.instance.getActiveProducts();
    for (final category in _categories) {
      if (category == 'All') {
        _categoryProducts[category] = allProducts;
      } else {
        _categoryProducts[category] = allProducts
            .where((p) => p.category == category)
            .toList();
      }
    }
  }

  List<ProductModel> get _filteredProducts {
    final selectedCategory = _categories[_selectedCategoryIndex];
    var products = _categoryProducts[selectedCategory] ?? [];

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.category.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Sort products
    switch (_selectedSort) {
      case 'Termurah':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Termahal':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Terpopuler':
        products.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case 'Terbaru':
      default:
        products.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return products;
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedSort = value;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedSort = 'Terbaru';
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _onProductTap(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product,
          onAddToCart: () {
            _showToast('${product.name} ditambahkan ke keranjang');
          },
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.pureWhite,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.pitchBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite(ProductModel product) {
    final updated = product.copyWith(isFavorite: !product.isFavorite);
    HiveDb.instance.saveProduct(updated);

    setState(() {
      for (final cat in _categoryProducts.keys) {
        final idx = _categoryProducts[cat]!.indexWhere(
          (p) => p.id == product.id,
        );
        if (idx != -1) {
          _categoryProducts[cat]![idx] = updated;
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchAndFilterBar(),
            const SizedBox(height: 8),
            _buildFilterPills(),
            const SizedBox(height: 8),
            Expanded(
              child: products.isEmpty
                  ? _buildEmptyState()
                  : _buildProductsGrid(products),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedSort != 'Terbaru';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: AppColors.blackGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Kategori',
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Row(
            children: [
              if (hasFilters)
                GestureDetector(
                  onTap: _resetFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Reset',
                          style: AppTextStyles.bodyXSmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.darkGrey),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTER BAR (SAMPINGAN)
  // ============================================================
  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search Bar (Expanded)
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderGrey),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pitchBlack.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pitchBlack),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.softGrey,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.softGrey,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.pureWhite,
                              size: 10,
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Sort Dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderGrey),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pitchBlack.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButton<String>(
              value: _selectedSort,
              onChanged: _onSortChanged,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, color: AppColors.pitchBlack),
              items: _sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        option == 'Termurah'
                            ? Icons.arrow_upward_rounded
                            : option == 'Termahal'
                            ? Icons.arrow_downward_rounded
                            : option == 'Terpopuler'
                            ? Icons.trending_up_rounded
                            : Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.darkGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(option),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER PILLS (CATEGORY)
  // ============================================================
  Widget _buildFilterPills() {
    return Container(
      height: 36,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          final category = _categories[index];
          final count = _categoryProducts[category]?.length ?? 0;

          return Padding(
            padding: EdgeInsets.only(
              right: index < _categories.length - 1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => _onCategorySelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.pitchBlack
                      : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.pitchBlack
                        : AppColors.borderGrey,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.pitchBlack.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: isSelected
                          ? AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.pureWhite)
                          : AppTextStyles.labelSmall.copyWith(color: AppColors.darkGrey),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.pureWhite.withValues(alpha: 0.2)
                              : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          count.toString(),
                          style: isSelected
                              ? AppTextStyles.bodyXSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.pureWhite.withValues(alpha: 0.8))
                              : AppTextStyles.bodyXSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.softGrey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PRODUCTS GRID
  // ============================================================
  Widget _buildProductsGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          onTap: () => _onProductTap(product),
          onFavoriteTap: () => _toggleFavorite(product),
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedSort != 'Terbaru';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: Icon(
                hasFilters
                    ? Icons.filter_alt_off_rounded
                    : Icons.inventory_2_outlined,
                size: 32,
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters ? 'Produk tidak ditemukan' : 'Belum ada produk',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: AppColors.pitchBlack),
            ),
            const SizedBox(height: 4),
            Text(
              hasFilters
                  ? 'Coba ubah filter atau kata kunci'
                  : 'Coba pilih kategori lain',
              style: AppTextStyles.bodySmall,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _resetFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pitchBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reset Filter',
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.pureWhite),
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

// ============================================================
// PRODUCT CARD
// ============================================================
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const _ProductCard({required this.product, this.onTap, this.onFavoriteTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.pitchBlack.withValues(alpha: 0.04),
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
                      top: Radius.circular(14),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pitchBlack.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          product.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: product.isFavorite
                              ? AppColors.error
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
                          style: AppTextStyles.bodyXSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.pureWhite),
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.pitchBlack, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      _formatPrice(product.price),
                      style: AppTextStyles.priceTextSmall.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toString(),
                                style: AppTextStyles.bodyXSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.darkGrey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey),
                        ),
                      ],
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

  String _formatPrice(double price) {
    final formatted = price.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }
}

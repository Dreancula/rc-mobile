import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/dummy/home_dummy_data.dart';
import '../../domain/models/product_model.dart';
import '../widgets/product_card.dart';

/// Search Screen with search bar and results
class SearchScreen extends StatefulWidget {
  final Function(ProductModel) onProductTap;

  const SearchScreen({
    super.key,
    required this.onProductTap,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<ProductModel> _searchResults = [];
  List<ProductModel> _allProducts = [];
  final List<String> _recentSearches = [];
  bool _isSearching = false;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'T-Shirt', 'Shirt', 'Pants', 'Jacket', 'Accessories'];

  @override
  void initState() {
    super.initState();
    _allProducts = HomeDummyData.products;
    _searchResults = _allProducts;
    // Auto focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _filterProducts(query);
    });
  }

  void _filterProducts(String query) {
    List<ProductModel> filtered = _allProducts;

    // Apply category filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((p) => p.category == _selectedFilter).toList();
    }

    // Apply search query
    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    _searchResults = filtered;
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterProducts(_searchController.text);
    });
  }

  void _addToRecentSearch(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  void _onSearchSubmit(String query) {
    _addToRecentSearch(query);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _selectedFilter = 'All';
      _searchResults = _allProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Content
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildSearchSuggestions(),
          ),
        ],
      ),
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
      title: _buildSearchField(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearch,
        onSubmitted: _onSearchSubmit,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
          prefixIcon: const Icon(Icons.search, color: AppColors.softGrey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.softGrey),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingM,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppConstants.spacingS),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () => _onFilterSelected(filter),
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlack : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.primaryWhite : AppColors.darkGrey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Pencarian Terakhir',
              actionText: 'Hapus',
              onAction: () => setState(() => _recentSearches.clear()),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Wrap(
              spacing: AppConstants.spacingS,
              runSpacing: AppConstants.spacingS,
              children: _recentSearches.map((search) {
                return _buildRecentSearchChip(search);
              }).toList(),
            ),
            const SizedBox(height: AppConstants.spacingXL),
          ],

          // Popular Searches
          _buildSectionHeader(title: 'Pencarian Populer'),
          const SizedBox(height: AppConstants.spacingS),
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: [
              'T-Shirt Basic',
              'Jeans Slim Fit',
              'Jaket Kulit',
              'Polo Shirt',
              'Sneakers',
              'Hoodie',
            ].map((search) {
              return _buildPopularSearchChip(search);
            }).toList(),
          ),
          const SizedBox(height: AppConstants.spacingXL),

          // Popular Categories
          _buildSectionHeader(title: 'Kategori Populer'),
          const SizedBox(height: AppConstants.spacingM),
          _buildPopularCategories(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.labelLarge),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: AppTextStyles.labelMedium.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentSearchChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _onSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 16, color: AppColors.softGrey),
            const SizedBox(width: 6),
            Text(text, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSearchChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _onSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderGrey),
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, size: 16, color: AppColors.softGrey),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCategories() {
    final categories = [
      {'icon': Icons.checkroom, 'name': 'T-Shirt', 'count': 24},
      {'icon': Icons.dry_cleaning, 'name': 'Shirt', 'count': 18},
      {'icon': Icons.accessibility, 'name': 'Pants', 'count': 15},
      {'icon': Icons.layers, 'name': 'Jacket', 'count': 12},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: AppConstants.spacingM,
        mainAxisSpacing: AppConstants.spacingM,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            _searchController.text = category['name'] as String;
            _onFilterSelected(category['name'] as String);
            _onSearch(category['name'] as String);
          },
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: Row(
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: AppColors.primaryBlack,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category['name'] as String,
                        style: AppTextStyles.labelLarge,
                      ),
                      Text(
                        '${category['count']} items',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Text(
            'Ditemukan ${_searchResults.length} produk',
            style: AppTextStyles.bodySmall,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: AppConstants.gridSpacing,
              mainAxisSpacing: AppConstants.gridSpacing,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(
                product: product,
                onTap: () => widget.onProductTap(product),
              );
            },
          ),
        ),
      ],
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
              Icons.search_off,
              size: 80,
              color: AppColors.lightGrey,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Produk tidak ditemukan',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Coba kata kunci lain atau\nperiksa ejaan pencarian Anda',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            TextButton(
              onPressed: _clearSearch,
              child: const Text('Hapus Filter'),
            ),
          ],
        ),
      ),
    );
  }
}

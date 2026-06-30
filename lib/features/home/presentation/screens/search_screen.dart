import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/category_model.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  final Function(ProductModel) onProductTap;

  const SearchScreen({super.key, required this.onProductTap});

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
  List<String> _filters = ['All'];
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    final db = HiveDb.instance;
    _categories = db.getCategories();
    _filters = ['All', ..._categories.map((c) => c.name)];
    _allProducts = db.getActiveProducts();
    _searchResults = _allProducts;

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

    if (_selectedFilter != 'All') {
      filtered = filtered.where((p) => p.category == _selectedFilter).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
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
    if (query.isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
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
    _focusNode.requestFocus();
  }

  void _onPopularSearchTap(String query) {
    _searchController.text = query;
    _addToRecentSearch(query);
    _onSearch(query);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildSearchSuggestions(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.pureWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.pitchBlack,
        onPressed: () => Navigator.pop(context),
      ),
      title: _buildSearchField(),
      toolbarHeight: 60,
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearch,
        onSubmitted: _onSearchSubmit,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pitchBlack),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.softGrey,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: _clearSearch,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.softGrey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.pureWhite,
                      size: 12,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER CHIPS
  // ============================================================
  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () => _onFilterSelected(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.pitchBlack : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.pitchBlack
                      : AppColors.borderGrey,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.pitchBlack.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  filter,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.pureWhite : AppColors.darkGrey,
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

  // ============================================================
  // SEARCH SUGGESTIONS
  // ============================================================
  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Pencarian Terakhir',
              actionText: 'Hapus',
              onAction: () => setState(() => _recentSearches.clear()),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return _buildChip(
                  text: search,
                  icon: Icons.history_rounded,
                  isRecent: true,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
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
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                gradient: AppColors.blackGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.labelLarge,
            ),
          ],
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: AppTextStyles.labelMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildChip({
    required String text,
    required IconData icon,
    required bool isRecent,
  }) {
    return GestureDetector(
      onTap: () => _onPopularSearchTap(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isRecent ? AppColors.lightGrey : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: isRecent ? null : Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.softGrey),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTextStyles.caption.copyWith(color: AppColors.darkGrey),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH RESULTS
  // ============================================================
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Ditemukan ${_searchResults.length} produk',
            style: AppTextStyles.caption,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Produk tidak ditemukan',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau periksa ejaan',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pitchBlack,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Hapus Filter',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
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

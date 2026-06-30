import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/theme/app_text_styles.dart';
import 'package:rc_mobile_v2/core/constants/app_constants.dart';
import 'package:rc_mobile_v2/features/home/domain/models/category_model.dart';

class AdminCategoryScreen extends StatefulWidget {
  final HiveDb db;
  const AdminCategoryScreen({super.key, required this.db});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  late HiveDb _db;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _iconOptions = [
    'tshirt',
    'shirt',
    'pants',
    'hoodie',
    'jacket',
    'accessories',
    'hat',
  ];

  static const Map<String, IconData> _iconMap = {
    'tshirt': Icons.checkroom_outlined,
    'shirt': Icons.dry_cleaning_outlined,
    'pants': Icons.straighten,
    'hoodie': Icons.layers_outlined,
    'jacket': Icons.layers_outlined,
    'accessories': Icons.watch_outlined,
    'hat': Icons.watch_outlined,
  };

  static const Map<String, Color> _colorMap = {
    'tshirt': Color(0xFFE74C3C),
    'shirt': Color(0xFF3498DB),
    'pants': Color(0xFF2ECC71),
    'hoodie': Color(0xFFE67E22),
    'jacket': Color(0xFFE67E22),
    'accessories': Color(0xFF9B59B6),
    'hat': Color(0xFF9B59B6),
  };

  @override
  void initState() {
    super.initState();
    _db = widget.db;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> get _categories {
    final c = _db.getCategories()..sort((a, b) => a.name.compareTo(b.name));
    return c;
  }

  List<CategoryModel> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where(
          (cat) => cat.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showForm({CategoryModel? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    String? selectedIcon = category?.iconPath;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          title: Center(
            child: Text(
              category == null ? 'Tambah Kategori' : 'Edit Kategori',
              style: AppTextStyles.heading4,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    filled: true,
                    fillColor: AppColors.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppConstants.spacingL),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Icon',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _iconOptions.map((key) {
                    final isSelected = selectedIcon == key;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = key),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.pitchBlack
                              : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.pitchBlack
                                : AppColors.borderGrey,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _iconMap[key] ?? Icons.category_outlined,
                          size: 24,
                          color: isSelected
                              ? AppColors.pureWhite
                              : _colorMap[key] ?? AppColors.charcoal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.spacingL),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.softBlackGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          selectedIcon != null
                              ? (_iconMap[selectedIcon] ?? Icons.category_outlined)
                              : Icons.category_rounded,
                          color: AppColors.pureWhite,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        nameCtrl.text.isEmpty
                            ? 'Preview Kategori'
                            : nameCtrl.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.pitchBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                if (category == null) {
                  await _db.saveCategory(
                    CategoryModel(
                      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      iconPath: selectedIcon,
                    ),
                  );
                } else {
                  await _db.saveCategory(category.copyWith(
                    name: name,
                    iconPath: selectedIcon,
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pitchBlack,
                foregroundColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(category == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteCategory(category.id);
              Navigator.pop(ctx);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cats = _filteredCategories;
    final productCounts = <String, int>{};
    for (final p in _db.getProducts()) {
      productCounts[p.category] = (productCounts[p.category] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.pitchBlack,
        foregroundColor: AppColors.pureWhite,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.softBlackGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppColors.pureWhite,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Manajemen Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pitchBlack,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pitchBlack,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_categories.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari kategori...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.softGrey,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.softGrey,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // List Kategori
          Expanded(
            child: cats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.category_outlined,
                          size: 48,
                          color: AppColors.softGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Kategori "${_searchQuery}" tidak ditemukan'
                              : 'Belum ada kategori',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.pitchBlack,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _clearSearch,
                            child: const Text('Hapus pencarian'),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.pitchBlack,
                    onRefresh: () async => setState(() {}),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                      itemCount: cats.length,
                      itemBuilder: (context, index) {
                        final cat = cats[index];
                        final count = productCounts[cat.name] ?? 0;

                        return GestureDetector(
                          onTap: () => _showForm(category: cat),
                          onLongPress: () => _confirmDelete(cat),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.borderGrey.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.pitchBlack.withValues(
                                    alpha: 0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.softBlackGradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    _iconMap[cat.iconPath] ?? Icons.category_rounded,
                                    color: AppColors.pureWhite,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.pitchBlack,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count produk',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.softGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

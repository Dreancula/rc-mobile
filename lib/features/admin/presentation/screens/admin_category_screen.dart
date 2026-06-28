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

  @override
  void initState() {
    super.initState();
    _db = widget.db;
  }

  List<CategoryModel> get _categories {
    final c = _db.getCategories()..sort((a, b) => a.name.compareTo(b.name));
    return c;
  }

  static const Map<String, IconData> _categoryIcons = {
    'folder': Icons.folder_rounded,
    'checkroom': Icons.checkroom_rounded,
    'smartphone': Icons.smartphone_rounded,
    'home': Icons.home_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'book': Icons.book_rounded,
    'fastfood': Icons.fastfood_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,
    'pets': Icons.pets_rounded,
    'brush': Icons.brush_rounded,
    'directions_car': Icons.directions_car_rounded,
    'music_note': Icons.music_note_rounded,
    'watch': Icons.watch_rounded,
    'diamond': Icons.diamond_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'backpack': Icons.backpack_rounded,
    'sports_basketball': Icons.sports_basketball_rounded,
    'beach_access': Icons.beach_access_rounded,
    'kitchen': Icons.kitchen_rounded,
    'chair': Icons.chair_rounded,
    'laptop': Icons.laptop_rounded,
    'headphones': Icons.headphones_rounded,
    'camera_alt': Icons.camera_alt_rounded,
    'accessibility_new': Icons.accessibility_new_rounded,
  };

  IconData _iconFromPath(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return Icons.folder_rounded;
    return _categoryIcons[iconPath] ?? Icons.folder_rounded;
  }

  void _showForm({CategoryModel? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    String selectedIcon = category?.iconPath ?? 'folder';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusL)),
          title: Center(
            child: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori',
                style: AppTextStyles.heading4),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori',
                      filled: true, fillColor: AppColors.lightGrey,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  Center(
                    child: Text('Pilih Icon', style: AppTextStyles.labelLarge),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _categoryIcons.length,
                      itemBuilder: (_, i) {
                        final entry = _categoryIcons.entries.elementAt(i);
                        final iconName = entry.key;
                        final icon = entry.value;
                        final isSelected = selectedIcon == iconName;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = iconName),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryBlack : AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(AppConstants.radiusS),
                              border: isSelected ? Border.all(color: AppColors.primaryBlack, width: 2) : null,
                            ),
                            child: Icon(icon, color: isSelected ? AppColors.pureWhite : AppColors.darkGrey, size: 24),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
                  await _db.saveCategory(CategoryModel(
                    id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    iconPath: selectedIcon,
                  ));
                } else {
                  await _db.saveCategory(category.copyWith(
                    name: name,
                    iconPath: selectedIcon,
                  ));
                }
                Navigator.pop(ctx);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async { await _db.deleteCategory(category.id); Navigator.pop(ctx); setState(() {}); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.pureWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categories;
    final productCounts = <String, int>{};
    for (final p in _db.getProducts()) {
      productCounts[p.category] = (productCounts[p.category] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite,
        elevation: 4, child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.category_rounded, color: AppColors.pureWhite, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Manajemen Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.pitchBlack, borderRadius: BorderRadius.circular(20)),
                  child: Text('${cats.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                ),
              ],
            ),
          ),
          Expanded(
            child: cats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 48, color: AppColors.softGrey),
                        const SizedBox(height: 12),
                        const Text('Belum ada kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.pitchBlack,
                    onRefresh: () async => setState(() {}),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: cats.length,
                      itemBuilder: (context, index) {
                        final cat = cats[index];
                        final count = productCounts[cat.name] ?? 0;
                        final iconData = _iconFromPath(cat.iconPath);
                        return GestureDetector(
                          onTap: () => _showForm(category: cat),
                          onLongPress: () => _confirmDelete(cat),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
                              boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(16)),
                                  child: Icon(iconData, color: AppColors.pureWhite, size: 28),
                                ),
                                const SizedBox(height: 12),
                                Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack), textAlign: TextAlign.center),
                                const SizedBox(height: 4),
                                Text('$count produk', style: const TextStyle(fontSize: 11, color: AppColors.softGrey)),
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

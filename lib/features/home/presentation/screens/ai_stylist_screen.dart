import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/models/product_model.dart';
import '../../data/repositories/cart_repository.dart';

class AiStylistScreen extends StatefulWidget {
  const AiStylistScreen({super.key});

  @override
  State<AiStylistScreen> createState() => _AiStylistScreenState();
}

class _AiStylistScreenState extends State<AiStylistScreen> {
  String? _selectedGender;
  final _weightCtrl = TextEditingController();
  String? _selectedStyle;
  List<ProductModel> _recommendations = [];
  String _recommendedSize = '';
  bool _showResults = false;

  static const _styleCategories = {
    'Casual': ['T-Shirt', 'Hoodie', 'Celana', 'Jaket'],
    'Formal': ['Kemeja', 'Celana'],
    'Sporty': ['T-Shirt', 'Jaket', 'Hoodie'],
    'Streetwear': ['T-Shirt', 'Jaket', 'Hoodie', 'Celana'],
  };

  static const Map<String, IconData> _styleIcons = {
    'Casual': Icons.checkroom_rounded,
    'Formal': Icons.dry_cleaning_rounded,
    'Sporty': Icons.sports_baseball_rounded,
    'Streetwear': Icons.shopping_bag_rounded,
  };

  static const Map<String, IconData> _genderIcons = {
    'Pria': Icons.man_rounded,
    'Wanita': Icons.woman_rounded,
  };

  String _sizeForWeight(double weight) {
    if (weight < 50) return 'S';
    if (weight < 60) return 'M';
    if (weight < 75) return 'L';
    return 'XL';
  }

  void _recommend() {
    final weight = double.tryParse(_weightCtrl.text);
    if (_selectedGender == null || weight == null || _selectedStyle == null) {
      _showToast('Lengkapi semua data terlebih dahulu');
      return;
    }

    final categories = _styleCategories[_selectedStyle]!;
    final allProducts = HiveDb.instance.getActiveProducts();
    final matched = allProducts
        .where((p) => categories.contains(p.category))
        .toList();

    setState(() {
      _recommendedSize = _sizeForWeight(weight);
      _recommendations = matched;
      _showResults = true;
    });
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.pitchBlack,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatPrice(double price) => CartRepository.formatPrice(price);

  double get _totalPrice =>
      _recommendations.fold(0.0, (sum, p) => sum + p.price);

  void _addToCart(ProductModel product) {
    if (product.stock <= 0) {
      _showToast('Stok ${product.name} habis', isError: true);
      return;
    }
    final size = product.availableSizes.contains(_recommendedSize)
        ? _recommendedSize
        : product.availableSizes.first;
    try {
      CartRepository().addItem(product: product, selectedSize: size);
      _showToast('${product.name} ($size) ditambahkan ke keranjang');
    } catch (e) {
      _showToast(e.toString(), isError: true);
    }
  }

  void _addAllToCart() {
    int added = 0;
    for (final product in _recommendations) {
      if (product.stock <= 0) continue;
      final size = product.availableSizes.contains(_recommendedSize)
          ? _recommendedSize
          : product.availableSizes.first;
      try {
        CartRepository().addItem(product: product, selectedSize: size);
        added++;
      } catch (_) {}
    }
    if (added > 0) {
      _showToast('$added produk ditambahkan ke keranjang');
    } else {
      _showToast('Tidak ada produk yang bisa ditambahkan', isError: true);
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildGenderSection(),
            const SizedBox(height: 20),
            _buildWeightSection(),
            const SizedBox(height: 20),
            _buildStyleSection(),
            const SizedBox(height: 24),
            _buildRecommendButton(),
            if (_showResults) ...[
              const SizedBox(height: 24),
              _buildResultsHeader(),
              const SizedBox(height: 12),
              if (_recommendations.isEmpty)
                _buildEmptyState()
              else ...[
                ..._recommendations.map(
                  (product) => _buildProductCard(product),
                ),
                const SizedBox(height: 12),
                _buildTotalPrice(),
                const SizedBox(height: 10),
                _buildAddAllButton(),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR (HEADER STYLE KAYAK KATEGORI)
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.pureWhite,
      elevation: 0,
      title: Row(
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
            const Text(
              'AI Stylist',
              style: AppTextStyles.heading3,
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pitchBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.pureWhite, size: 12),
                const SizedBox(width: 4),
                  Text(
                    'AI',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.pureWhite,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  // ============================================================
  // HEADER (GAUSA PAKE LAGI)
  // ============================================================
  Widget _buildHeader() {
    return const SizedBox.shrink();
  }

  // ============================================================
  // GENDER SECTION (TANPA GARIS)
  // ============================================================
  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.pitchBlack,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _genderChip('Pria'),
            const SizedBox(width: 10),
            _genderChip('Wanita'),
          ],
        ),
      ],
    );
  }

  Widget _genderChip(String label) {
    final selected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.pitchBlack : AppColors.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.pitchBlack : AppColors.borderGrey,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.pitchBlack.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _genderIcons[label]!,
                color: selected ? AppColors.pureWhite : AppColors.darkGrey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.pureWhite : AppColors.darkGrey,
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WEIGHT SECTION (TANPA GARIS)
  // ============================================================
  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Berat Badan (kg)',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.pitchBlack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: TextField(
            controller: _weightCtrl,
            keyboardType: TextInputType.number,
            style: AppTextStyles.priceTextSmall,
            decoration: InputDecoration(
              hintText: 'Masukkan berat badan',
              hintStyle: AppTextStyles.caption.copyWith(fontSize: 14),
              prefixIcon: const Icon(
                Icons.fitness_center_rounded,
                size: 18,
                color: AppColors.softGrey,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STYLE SECTION (TANPA GARIS)
  // ============================================================
  Widget _buildStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Gaya',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.pitchBlack,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _styleCategories.keys.map((style) {
            final selected = _selectedStyle == style;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedStyle = selected ? null : style;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.pitchBlack : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.pitchBlack
                        : AppColors.borderGrey,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
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
                    Icon(
                      _styleIcons[style]!,
                      size: 16,
                      color: selected
                          ? AppColors.pureWhite
                          : AppColors.darkGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      style,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? AppColors.pureWhite
                            : AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // RECOMMEND BUTTON
  // ============================================================
  Widget _buildRecommendButton() {
    final isReady =
        _selectedGender != null &&
        _weightCtrl.text.isNotEmpty &&
        _selectedStyle != null;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isReady ? _recommend : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isReady ? AppColors.pitchBlack : AppColors.lightGrey,
          foregroundColor: AppColors.pureWhite,
          disabledBackgroundColor: AppColors.lightGrey,
          disabledForegroundColor: AppColors.softGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 18),
            const SizedBox(width: 8),
            Text(
              isReady ? 'Rekomendasikan' : 'Lengkapi Data',
              style: AppTextStyles.priceTextSmall,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESULTS HEADER
  // ============================================================
  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pitchBlack,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'UKURAN: $_recommendedSize',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.pureWhite,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_recommendations.length} produk',
            style: AppTextStyles.caption,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _selectedStyle ?? '',
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 9,
                color: AppColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.softGrey),
            const SizedBox(height: 12),
            Text(
              'Tidak ada rekomendasi untuk gaya ini',
              style: AppTextStyles.priceTextSmall.copyWith(
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba pilih gaya lain',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================
  Widget _buildProductCard(ProductModel product) {
    final size = product.availableSizes.contains(_recommendedSize)
        ? _recommendedSize
        : product.availableSizes.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: AppColors.pitchBlack.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                imageUrl: product.imageUrl,
                width: 72,
                height: 72,
                borderRadius: 8,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.pitchBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(product.price),
                    style: AppTextStyles.priceTextSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pitchBlack,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          size,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 9,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (product.stock <= 0)
                        Text(
                          'HABIS',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        )
                      else
                        Text(
                          'Stok: ${product.stock}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: product.stock > 0 ? () => _addToCart(product) : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: product.stock > 0
                      ? AppColors.pitchBlack
                      : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: product.stock > 0
                      ? [
                          BoxShadow(
                            color: AppColors.pitchBlack.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.add_shopping_cart_rounded,
                  color: product.stock > 0
                      ? AppColors.pureWhite
                      : AppColors.softGrey,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOTAL PRICE
  // ============================================================
  Widget _buildTotalPrice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Harga',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.pitchBlack,
            ),
          ),
          Text(
            _formatPrice(_totalPrice),
            style: AppTextStyles.priceText,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD ALL BUTTON
  // ============================================================
  Widget _buildAddAllButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _recommendations.isEmpty ? null : _addAllToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pitchBlack,
          foregroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Masukkan Semua ke Keranjang',
              style: AppTextStyles.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

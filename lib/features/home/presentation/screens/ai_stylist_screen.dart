import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
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

  String _sizeForWeight(double weight) {
    if (weight < 50) return 'S';
    if (weight < 60) return 'M';
    if (weight < 75) return 'L';
    return 'XL';
  }

  void _recommend() {
    final weight = double.tryParse(_weightCtrl.text);
    if (_selectedGender == null || weight == null || _selectedStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lengkapi semua data terlebih dahulu'),
          backgroundColor: AppColors.primaryBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  String _formatPrice(double price) => CartRepository.formatPrice(price);

  double get _totalPrice =>
      _recommendations.fold(0.0, (sum, p) => sum + p.price);

  void _addToCart(ProductModel product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok ${product.name} habis'),
          backgroundColor: AppColors.primaryBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final size = product.availableSizes.contains(_recommendedSize)
        ? _recommendedSize
        : product.availableSizes.first;
    try {
      CartRepository().addItem(product: product, selectedSize: size);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} ($size) ditambahkan ke keranjang'),
          backgroundColor: AppColors.primaryBlack,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$added produk ditambahkan ke keranjang'),
        backgroundColor: AppColors.primaryBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        title: const Text(
          'AI STYLIST',
          style: AppTextStyles.heading4,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primaryBlack, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'STYLE RECOMMENDATION',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            _sectionLabel('PILIH JENIS KELAMIN'),
            const SizedBox(height: 10),
            Row(
              children: [
                _genderChip('Pria', Icons.male),
                const SizedBox(width: 12),
                _genderChip('Wanita', Icons.female),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel('BERAT BADAN (KG)'),
            const SizedBox(height: 10),
            TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Contoh: 65',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('PILIH GAYA'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _styleCategories.keys.map((style) {
                final selected = _selectedStyle == style;
                return ChoiceChip(
                  label: Text(
                    style.toUpperCase(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: selected ? AppColors.pureWhite : AppColors.primaryBlack,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.primaryBlack,
                  backgroundColor: AppColors.lightGrey,
                  side: BorderSide(
                    color: selected ? AppColors.primaryBlack : AppColors.borderGrey,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (v) => setState(() => _selectedStyle = v ? style : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _recommend,
                icon: const Icon(Icons.auto_awesome, color: AppColors.pureWhite),
                label: const Text(
                  'REKOMENDASIKAN',
                  style: AppTextStyles.buttonText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
              ),
            ),

            if (_showResults) ...[
              const SizedBox(height: 32),
              Divider(color: AppColors.borderGrey, height: 1),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlack,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'UKURAN: $_recommendedSize',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_recommendations.length} produk',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_recommendations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, color: AppColors.softGrey, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada rekomendasi untuk gaya ini',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ..._recommendations.map((product) => _buildProductCard(product)),

                const SizedBox(height: 16),

                // Total price
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Harga',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatPrice(_totalPrice),
                        style: AppTextStyles.priceText,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _addAllToCart,
                    icon: const Icon(Icons.shopping_cart, color: AppColors.pureWhite),
                    label: const Text(
                      'MASUKKAN KE KERANJANG',
                      style: AppTextStyles.buttonText,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.primaryBlack,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        fontSize: 11,
      ),
    );
  }

  Widget _genderChip(String label, IconData icon) {
    final selected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlack : AppColors.lightGrey,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: selected ? AppColors.primaryBlack : AppColors.borderGrey,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? AppColors.pureWhite : AppColors.primaryBlack, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: selected ? AppColors.pureWhite : AppColors.primaryBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final size = product.availableSizes.contains(_recommendedSize)
        ? _recommendedSize
        : product.availableSizes.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProductImage(
              imageUrl: product.imageUrl,
              width: 80,
              height: 80,
              borderRadius: AppConstants.radiusS,
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlack,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          size,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.stock <= 0)
                        Text(
                          'HABIS',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
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
            const SizedBox(width: 8),

            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: product.stock > 0 ? () => _addToCart(product) : null,
                icon: Icon(
                  Icons.add_shopping_cart,
                  color: product.stock > 0 ? AppColors.primaryBlack : AppColors.softGrey,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: product.stock > 0
                      ? AppColors.lightGrey
                      : AppColors.borderGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
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

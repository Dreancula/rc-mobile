import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/features/home/domain/models/product_model.dart';

class AdminProductScreen extends StatefulWidget {
  final HiveDb db;
  const AdminProductScreen({super.key, required this.db});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  late HiveDb _db;
  String _filterCategory = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _db = widget.db;
  }

  List<ProductModel> get _products {
    var list = _db.getProducts();
    if (_filterCategory != 'Semua') {
      list = list.where((p) => p.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<String> get _categories => ['Semua', ..._db.getCategories().map((c) => c.name)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductSheet(),
        backgroundColor: AppColors.pitchBlack,
        foregroundColor: AppColors.pureWhite,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.inventory_2_rounded, color: AppColors.pureWhite, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Manajemen Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.pitchBlack, borderRadius: BorderRadius.circular(20)),
                      child: Text('${_db.getProducts().length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.softGrey),
                    filled: true, fillColor: AppColors.lightGrey,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.map((cat) {
                      final isSelected = cat == _filterCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.blackGradient : null,
                              color: isSelected ? null : AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? AppColors.pureWhite : AppColors.softGrey))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.softGrey),
                        const SizedBox(height: 12),
                        const Text('Belum ada produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.pitchBlack,
                    onRefresh: () async => setState(() {}),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) => _buildProductCard(_products[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showProductSheet(product: product),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(product.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Rp ${_f(product.price)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(4)),
                      child: Text(product.category, style: const TextStyle(fontSize: 10, color: AppColors.softGrey)),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: product.isActive,
                    onChanged: (_) { _db.toggleProductActive(product.id); setState(() {}); },
                    activeTrackColor: AppColors.pitchBlack,
                    inactiveThumbColor: AppColors.softGrey,
                  ),
                  Text(product.isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: 9, color: product.isActive ? AppColors.success : AppColors.softGrey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder());
    }
    if (url.isNotEmpty) {
      return Image.file(File(url), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder());
    }
    return _imgPlaceholder();
  }

  Widget _imgPlaceholder() => Container(color: AppColors.lightGrey, child: const Icon(Icons.image_outlined, color: AppColors.softGrey, size: 24));

  void _showProductSheet({ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductFormSheet(db: _db, product: product, onSaved: () => setState(() {})),
    );
  }

  String _f(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _ProductFormSheet extends StatefulWidget {
  final HiveDb db;
  final ProductModel? product;
  final VoidCallback onSaved;
  const _ProductFormSheet({required this.db, this.product, required this.onSaved});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late HiveDb _db;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _priceCtrl, _descCtrl, _stockCtrl, _weightCtrl;
  late String _category, _imageUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _db = widget.db;
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '');
    _weightCtrl = TextEditingController(text: p != null ? p.weight.toStringAsFixed(0) : '');
    _category = p?.category ?? '';
    _imageUrl = p?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _stockCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (!mounted) return;
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null && mounted) setState(() => _imageUrl = picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal membuka galeri: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori'))); return; }
    setState(() => _isSaving = true);
    final product = ProductModel(
      id: _isEditing ? widget.product!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      imageUrl: _imageUrl,
      category: _category,
      description: _descCtrl.text.trim(),
      stock: int.parse(_stockCtrl.text.trim()),
      weight: double.parse(_weightCtrl.text.trim()),
      isActive: widget.product?.isActive ?? true,
    );
    await _db.saveProduct(product);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: AppColors.pureWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderGrey, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEditing ? 'Edit Produk' : 'Tambah Produk', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.3)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.lightGrey, shape: BoxShape.circle), child: const Icon(Icons.close, size: 20, color: AppColors.pitchBlack)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity, height: 180,
                        decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderGrey)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _imageUrl.isNotEmpty
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    (_imageUrl.startsWith('http://') || _imageUrl.startsWith('https://')
                                        ? Image.network(_imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgBig())
                                        : Image.file(File(_imageUrl), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgBig())),
                                    Positioned(
                                      top: 8, right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _imageUrl = ''),
                                        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.pitchBlack.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: AppColors.pureWhite)),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8, left: 0, right: 0,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: AppColors.pitchBlack.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                                          child: const Text('Tap untuk ganti foto', style: TextStyle(fontSize: 11, color: AppColors.pureWhite)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : _imgBig(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _field('Nama Produk'),
                    const SizedBox(height: 8),
                    TextFormField(controller: _nameCtrl, decoration: _inputDec(), validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    _field('Harga'),
                    const SizedBox(height: 8),
                    TextFormField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: _inputDec('Rp'),
                      validator: (v) { if (v == null || v.trim().isEmpty) return 'Wajib diisi'; final p = double.tryParse(v.trim()); if (p == null || p <= 0) return 'Tidak valid'; return null; }),
                    const SizedBox(height: 16),
                    _field('Kategori'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _category.isNotEmpty ? _category : null,
                      items: _db.getCategories().map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _category = v); },
                      decoration: _inputDec('Pilih'),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib pilih' : null,
                    ),
                    const SizedBox(height: 16),
                    _field('Stok'),
                    const SizedBox(height: 8),
                    TextFormField(controller: _stockCtrl, keyboardType: TextInputType.number, decoration: _inputDec('Jumlah stok'),
                      validator: (v) { if (v == null || v.trim().isEmpty) return 'Wajib diisi'; final s = int.tryParse(v.trim()); if (s == null || s < 0) return 'Tidak valid'; return null; }),
                    const SizedBox(height: 16),
                    _field('Berat (gram)'),
                    const SizedBox(height: 8),
                    TextFormField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: _inputDec('Contoh: 250'),
                      validator: (v) { if (v == null || v.trim().isEmpty) return 'Wajib diisi'; final w = double.tryParse(v.trim()); if (w == null || w <= 0) return 'Tidak valid'; return null; }),
                    const SizedBox(height: 16),
                    _field('Deskripsi'),
                    const SizedBox(height: 8),
                    TextFormField(controller: _descCtrl, maxLines: 4, decoration: _inputDec('Deskripsi produk')),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pitchBlack, foregroundColor: AppColors.pureWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4, shadowColor: AppColors.pitchBlack.withValues(alpha: 0.3),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pureWhite))
                            : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Produk', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: OutlinedButton(
                          onPressed: () { _db.deleteProduct(widget.product!.id); widget.onSaved(); Navigator.pop(context); },
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text('Hapus Produk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label) => Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.pitchBlack));

  InputDecoration _inputDec([String? hint]) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
    filled: true, fillColor: AppColors.lightGrey,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );

  Widget _imgBig() => Container(color: AppColors.lightGrey, child: const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.image_outlined, size: 48, color: AppColors.softGrey),
      SizedBox(height: 8),
      Text('Tap untuk pilih foto', style: TextStyle(fontSize: 13, color: AppColors.softGrey)),
    ],
  ));
}

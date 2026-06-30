import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/theme/app_text_styles.dart';
import 'package:rc_mobile_v2/core/constants/app_constants.dart';
import 'package:rc_mobile_v2/core/widgets/product_image.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';

class ReviewScreen extends StatefulWidget {
  final OrderModel order;

  const ReviewScreen({super.key, required this.order});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final HiveDb _db = HiveDb.instance;
  final ImagePicker _picker = ImagePicker();
  late Map<String, int> _ratings;
  late Map<String, TextEditingController> _comments;
  late Map<String, List<String>> _photos;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _ratings = {};
    _comments = {};
    _photos = {};
    for (final item in widget.order.items) {
      _ratings[item.id] = 5;
      _comments[item.id] = TextEditingController();
      _photos[item.id] = [];
    }
  }

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(String productId) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _photos[productId]!.add(picked.path);
      });
    }
  }

  void _removePhoto(String productId, int index) {
    setState(() {
      _photos[productId]!.removeAt(index);
    });
  }

  bool get _canSubmit {
    return widget.order.items.every((item) {
      final comment = _comments[item.id]?.text.trim() ?? '';
      return comment.isNotEmpty;
    });
  }

  Future<void> _submit() async {
    final session = _db.getUserSession();
    if (session == null) return;

    setState(() => _isSubmitting = true);

    try {
      for (final item in widget.order.items) {
        final comment = _comments[item.id]?.text.trim() ?? '';
        final photos = _photos[item.id] ?? [];
        final rating = _ratings[item.id] ?? 5;

        final bool hasContent = comment.isNotEmpty || photos.isNotEmpty || rating != 5;
        if (!hasContent) continue;

        await _db.addReview({
          'id': 'rev_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
          'orderId': widget.order.id,
          'productId': item.id,
          'productName': item.name,
          'productImage': item.imageUrl,
          'userEmail': session['email'],
          'userName': session['name'] ?? 'User',
          'rating': _ratings[item.id] ?? 5,
          'comment': comment,
          'photos': _photos[item.id] ?? [],
          'createdAt': DateTime.now().toIso8601String(),
          'adminReply': null,
          'repliedAt': null,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ulasan berhasil dikirim'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim ulasan: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Berikan Ulasan', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      gradient: AppColors.blackGradient,
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          ),
                          child: const Icon(Icons.star_rounded, color: AppColors.pureWhite, size: 24),
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pesanan #${widget.order.id.substring(widget.order.id.length - 6)}',
                                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.pureWhite),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Beri rating dan ulasan untuk setiap produk',
                                style: AppTextStyles.caption.copyWith(color: AppColors.pureWhite),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  ...widget.order.items.map((item) {
                    return _buildReviewCard(item);
                  }),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic item) {
    final productId = item.id;
    final rating = _ratings[productId] ?? 5;
    final commentCtrl = _comments[productId]!;

    return Container(
      key: ValueKey(productId),
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  child: ProductImage(
                    imageUrl: item.imageUrl,
                    width: 50,
                    height: 50,
                    borderRadius: AppConstants.radiusS,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTextStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () => setState(() => _ratings[productId] = i + 1),
                  icon: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: i < rating ? Colors.amber : AppColors.borderGrey,
                    size: 36,
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppConstants.spacingM, 0, AppConstants.spacingM, AppConstants.spacingM),
            child: TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis ulasan Anda...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppConstants.spacingM),
              ),
            ),
          ),
          // Photo picker
          Padding(
            padding: const EdgeInsets.fromLTRB(AppConstants.spacingM, 0, AppConstants.spacingM, AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 80,
                  child: Row(
                    children: [
                      ..._photos[productId]!.asMap().entries.map((entry) {
                        final i = entry.key;
                        final path = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                  border: Border.all(color: AppColors.borderGrey),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppConstants.radiusM - 1),
                                  child: Image.file(File(path), fit: BoxFit.cover, width: 72, height: 72),
                                ),
                              ),
                              Positioned(
                                top: -4, right: -4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(productId, i),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 12, color: AppColors.pureWhite),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (_photos[productId]!.length < 3)
                        GestureDetector(
                          onTap: () => _pickPhoto(productId),
                          child: Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                              border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined, size: 22, color: AppColors.softGrey),
                                const SizedBox(height: 2),
                                Text('Tambah', style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_isSubmitting || !_canSubmit) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlack,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pureWhite))
                : const Text('Kirim Ulasan', style: AppTextStyles.buttonText),
          ),
        ),
      ),
    );
  }
}
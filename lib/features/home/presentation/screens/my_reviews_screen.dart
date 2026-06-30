import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/theme/app_text_styles.dart';
import 'package:rc_mobile_v2/core/constants/app_constants.dart';
import 'package:rc_mobile_v2/core/widgets/product_image.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final HiveDb _db = HiveDb.instance;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    final session = _db.getUserSession();
    final email = session?['email'] as String? ?? '';
    setState(() {
      _isLoading = true;
      _reviews = _db.getReviewsByUserEmail(email);
      _isLoading = false;
    });
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
        title: const Text('Ulasan Saya', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pitchBlack))
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_outline_rounded, size: 40, color: AppColors.softGrey),
                      ),
                      const SizedBox(height: 20),
                      Text('Belum ada ulasan', style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Ulasan produk yang sudah kamu beli\nakan muncul di sini', style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey, height: 1.5), textAlign: TextAlign.center),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.pitchBlack,
                  onRefresh: () async => _loadReviews(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
                  ),
                ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num).toInt();
    final productName = review['productName'] as String? ?? 'Produk';
    final productImage = review['productImage'] as String? ?? '';
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['createdAt'] as String? ?? '';
    final adminReply = review['adminReply'] as String?;
    final hasReply = adminReply != null && adminReply.isNotEmpty;
    final photos = (review['photos'] as List?)?.cast<String>() ?? <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  child: ProductImage(imageUrl: productImage, width: 48, height: 48, borderRadius: AppConstants.radiusM),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName, style: AppTextStyles.priceTextSmall.copyWith(color: AppColors.pitchBlack), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(_formatDate(createdAt), style: AppTextStyles.bodyXSmall.copyWith(color: AppColors.softGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rating stars
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            child: Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
          ),
          // Comment
          if (comment.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.spacingM, 8, AppConstants.spacingM, 0),
              child: Text(comment, style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey, height: 1.5)),
            ),
          ],
          // Photos
          if (photos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.spacingM, 10, AppConstants.spacingM, 0),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM - 1),
                        child: Image.file(File(photos[i]), fit: BoxFit.cover, width: 72, height: 72),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          // Admin reply
          if (hasReply) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.spacingM, 10, AppConstants.spacingM, 0),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlack.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.reply, size: 14, color: AppColors.primaryBlack),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Balasan Admin', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.softGrey)),
                          const SizedBox(height: 4),
                          Text(adminReply, style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppConstants.spacingM),
        ],
      ),
    );
  }
}

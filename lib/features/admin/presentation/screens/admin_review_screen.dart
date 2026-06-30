import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/core/theme/app_text_styles.dart';
import 'package:rc_mobile_v2/core/constants/app_constants.dart';

class AdminReviewScreen extends StatefulWidget {
  final HiveDb db;
  const AdminReviewScreen({super.key, required this.db});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  late HiveDb _db;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _db = widget.db;
    _loadReviews();
  }

  void _loadReviews() {
    setState(() {
      _isLoading = true;
      _reviews = _db.getAllReviews();
      _isLoading = false;
    });
  }

  void _showReplyDialog(Map<String, dynamic> review) {
    final replyCtrl = TextEditingController(text: review['adminReply'] as String? ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusL)),
        title: const Text('Balas Ulasan', style: AppTextStyles.heading4),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review['userName'] as String? ?? '', style: AppTextStyles.labelLarge),
                        const Spacer(),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < ((review['rating'] as num?)?.toInt() ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(review['comment'] as String? ?? '', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: replyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Tulis balasan...',
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                autofocus: true,
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
              final reply = replyCtrl.text.trim();
              if (reply.isEmpty) return;
              await _db.updateReviewReply(review['id'] as String, reply);
              Navigator.pop(ctx);
              _loadReviews();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pitchBlack,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kirim Balasan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
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
                  child: const Icon(Icons.star_rounded, color: AppColors.pureWhite, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Ulasan Pembeli', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.pitchBlack, borderRadius: BorderRadius.circular(20)),
                  child: Text('${_reviews.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                ),
              ],
            ),
          ),
          Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.pitchBlack))
                  : _reviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_outline_rounded, size: 48, color: AppColors.softGrey),
                              const SizedBox(height: 12),
                              const Text('Belum ada ulasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                              const SizedBox(height: 8),
                              const Text('Tarik ke bawah untuk memperbarui', style: TextStyle(fontSize: 12, color: AppColors.softGrey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _loadReviews(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
                          ),
                        ),
          ),
        ],
      ),
    );
  }

  bool _hasPhotos(Map<String, dynamic> review) {
    final photos = (review['photos'] as List?)?.cast<String>() ?? <String>[];
    return photos.isNotEmpty;
  }

  Widget _buildReviewPhotos(Map<String, dynamic> review) {
    final photos = (review['photos'] as List?)?.cast<String>() ?? <String>[];
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          return Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusM - 1),
              child: Image.file(File(photos[i]), fit: BoxFit.cover, width: 60, height: 60),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num).toInt();
    final userName = review['userName'] as String? ?? 'User';
    final productName = review['productName'] as String? ?? 'Produk';
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['createdAt'] as String? ?? '';
    final date = DateTime.tryParse(createdAt);
    final adminReply = review['adminReply'] as String?;
    final hasReply = adminReply != null && adminReply.isNotEmpty;

    return GestureDetector(
      onTap: () => _showReplyDialog(review),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryBlack,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppColors.pureWhite, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: AppTextStyles.labelLarge),
                      if (date != null)
                        Text('${date.day}/${date.month}/${date.year}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasReply ? AppColors.success.withValues(alpha: 0.1) : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                  ),
                  child: Text(
                    hasReply ? 'Sudah dibalas' : 'Belum dibalas',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hasReply ? AppColors.success : AppColors.softGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(productName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey)),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 18,
                );
              }),
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(comment, style: AppTextStyles.bodyMedium),
            ],
            if (_hasPhotos(review)) ...[
              const SizedBox(height: AppConstants.spacingS),
              _buildReviewPhotos(review),
            ],
            if (hasReply) ...[
              const SizedBox(height: AppConstants.spacingS),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.reply, size: 16, color: AppColors.softGrey),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Balasan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.softGrey)),
                          const SizedBox(height: 2),
                          Text(adminReply, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
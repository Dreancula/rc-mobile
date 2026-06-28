import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

class ComplaintScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final double orderTotal;

  const ComplaintScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.orderTotal,
  });

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _descCtrl = TextEditingController();
  final List<File> _photos = [];
  bool _isSubmitting = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submitComplaint() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi deskripsi komplain terlebih dahulu'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final session = HiveDb.instance.getUserSession();
    final complaint = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'orderId': widget.orderId,
      'orderNumber': widget.orderNumber,
      'orderTotal': widget.orderTotal,
      'userEmail': session?['email'] ?? '',
      'userName': session?['name'] ?? '',
      'description': desc,
      'photos': _photos.map((f) => f.path).toList(),
      'status': 'pending',
      'refundAmount': widget.orderTotal * 0.3,
      'createdAt': DateTime.now().toIso8601String(),
      'resolvedAt': null,
    };

    await HiveDb.instance.addComplaint(complaint);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Komplain berhasil dikirim, menunggu respon admin'),
        backgroundColor: AppColors.primaryBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
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
        title: const Text('Ajukan Komplain', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: const Icon(Icons.receipt_outlined, size: 20, color: AppColors.primaryBlack),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pesanan #${widget.orderNumber}', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          'Total: Rp ${widget.orderTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingXL),

            // Description
            Text('Deskripsi Komplain', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppConstants.spacingS),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Jelaskan masalah yang Anda alami...',
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

            const SizedBox(height: AppConstants.spacingL),

            // Photos
            Text('Foto Bukti', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Tambahkan foto sebagai bukti pendukung',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.softGrey),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Wrap(
              spacing: AppConstants.spacingM,
              runSpacing: AppConstants.spacingM,
              children: [
                ..._photos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.radiusM - 1),
                          child: Image.file(file, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: AppColors.pureWhite),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_photos.length < 3)
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        border: Border.all(color: AppColors.borderGrey, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppColors.softGrey, size: 28),
                          const SizedBox(height: 4),
                          Text('Tambah', style: AppTextStyles.caption.copyWith(color: AppColors.softGrey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingXL),

            // Refund Info
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.darkGrey, size: 20),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      'Jika komplain disetujui, Anda akan mendapatkan pengembalian dana sebesar 30% dari total pesanan (Rp ${(widget.orderTotal * 0.3).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}).',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkGrey, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingXL),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlack,
                  disabledBackgroundColor: AppColors.lightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pureWhite),
                      )
                    : const Text('Kirim Komplain', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

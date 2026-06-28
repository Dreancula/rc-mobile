import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    // Network image
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      image = Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingIndicator();
        },
      );
    }
    // Asset image (starts with 'assets/')
    else if (imageUrl.startsWith('assets/')) {
      image = Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    // Local file image
    else if (imageUrl.isNotEmpty) {
      image = Image.file(
        File(imageUrl),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    // Empty/placeholder
    else {
      image = _placeholder();
    }

    if (borderRadius != null && borderRadius! > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: image,
      );
    }
    return image;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.lightGrey,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.softGrey,
          size: 32,
        ),
      ),
    );
  }

  Widget _loadingIndicator() {
    return Container(
      width: width,
      height: height,
      color: AppColors.lightGrey,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.softGrey,
        ),
      ),
    );
  }
}

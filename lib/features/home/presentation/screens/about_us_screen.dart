import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
        title: const Text('Tentang Kami', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.checkroom,
                color: AppColors.pureWhite,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Republik Casual',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.pitchBlack,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Casual Fashion Destination',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGrey,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Republik Casual adalah toko fashion online yang menyediakan berbagai pakaian casual berkualitas. '
              'Kami berkomitmen untuk memberikan produk terbaik dengan harga terjangkau.',
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Berdiri sejak 2024, kami terus berkembang untuk memenuhi kebutuhan fashion casual '
              'masyarakat Indonesia. Dari T-Shirt, Kemeja, Jaket, Hoodie, hingga Celana — '
              'semua tersedia di Republik Casual.',
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Divider(color: AppColors.borderGrey),
            const SizedBox(height: 24),
            _infoRow(Icons.location_on_outlined, 'Jl. Margonda No.8, Depok'),
            const SizedBox(height: 12),
            _infoRow(Icons.email_outlined, 'hello@republikcasual.com'),
            const SizedBox(height: 12),
            _infoRow(Icons.phone_outlined, '+62 812-3456-7890'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.softGrey),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGrey),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_logo.dart';

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
            const AppLogo(size: 100),
            const SizedBox(height: 20),
            Text(
              'Republik Casual',
              style: AppTextStyles.heading2.copyWith(
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
            _sectionText(
              'Selamat datang di Republik Casual, "negara" digital tempat di mana '
              'kenyamanan berdaulat penuh dan tampil keren nggak pernah ribet!',
            ),
            const SizedBox(height: 20),
            _sectionText(
              'Kami tahu banget rasanya terjebak di antara pengen tampil modis '
              'tapi malas pakai baju yang bikin gerah atau kaku. Itulah kenapa '
              'Republik Casual lahir. Kami mengurasi fashion items harian terbaik—'
              'mulai dari streetwear yang hype, kaos esensial yang super nyaman, '
              'sampai outfit nongkrong yang effortlessly cool—semuanya dikemas '
              'dalam satu aplikasi yang antiribet.',
            ),
            const SizedBox(height: 20),
            _sectionText(
              'Bagi kami, kasual itu bukan cuma soal kaos oblong dan celana jins. '
              'Kasual adalah sebuah statement bahwa kamu bisa menaklukkan hari '
              'dengan caramu sendiri, tanpa harus mengorbankan kenyamanan. '
              'Di Republik Casual, semua warga bebas berekspresi, bereksperimen, '
              'dan jadi versi terbaik dari diri mereka sendiri.',
            ),
            const SizedBox(height: 20),
            _sectionText(
              'Aturan utama di Republik kita cuma satu: Keep it casual, keep it real. '
              'Selamat bergabung dan selamat menjelajah, Warga Republik!',
            ),
            const SizedBox(height: 40),
            const Divider(color: AppColors.borderGrey),
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

  Widget _sectionText(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyLarge.copyWith(
        height: 1.6,
      ),
      textAlign: TextAlign.center,
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

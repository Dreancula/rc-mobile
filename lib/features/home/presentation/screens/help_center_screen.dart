import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = [
    {
      'q': 'Bagaimana cara melakukan pemesanan?',
      'a': 'Pilih produk yang diinginkan, tambahkan ke keranjang, lalu lakukan checkout. Isi alamat pengiriman dan pilih metode pembayaran.',
    },
    {
      'q': 'Metode pembayaran apa saja yang tersedia?',
      'a': 'Saat ini tersedia pembayaran melalui QRIS dan COD (Bayar di Tempat).',
    },
    {
      'q': 'Berapa lama estimasi pengiriman?',
      'a': 'Estimasi pengiriman tergantung kurir yang dipilih. GoSend (hari yang sama), SiCepat BEST (1 hari), JNE/J&T Reguler (2-3 hari).',
    },
    {
      'q': 'Bagaimana cara menggunakan voucher diskon?',
      'a': 'Voucher diskon dapat digunakan saat checkout dengan metode pembayaran QRIS. Voucher akan otomatis terdeteksi jika tersedia.',
    },
    {
      'q': 'Bagaimana cara menghubungi admin?',
      'a': 'Kamu bisa menggunakan fitur Chat yang tersedia di halaman Riwayat atau melalui menu Chat di halaman utama.',
    },
    {
      'q': 'Apakah bisa membatalkan pesanan?',
      'a': 'Pesanan dapat dibatalkan selama status masih "Menunggu Pembayaran". Hubungi admin melalui fitur Chat untuk bantuan lebih lanjut.',
    },
  ];

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
        title: const Text('Pusat Bantuan', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlack,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      faq['q']!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  faq['a']!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.softGrey,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

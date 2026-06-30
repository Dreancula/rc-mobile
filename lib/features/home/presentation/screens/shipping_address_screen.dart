import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/location_helper.dart';
import '../../../../data/indonesia_regions.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _selectedProvince = '';
  String _selectedCity = '';
  List<String> _cities = [];
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = HiveDb.instance.getUserPhone();
    _addressCtrl.text = HiveDb.instance.getUserAddress();
    _selectedProvince = HiveDb.instance.getUserProvince();
    _selectedCity = HiveDb.instance.getUserCity();
    if (_selectedProvince.isNotEmpty) {
      _cities = IndonesiaRegions.citiesByProvince[_selectedProvince] ?? [];
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _buildFullAddress() {
    final parts = <String>[];
    if (_addressCtrl.text.trim().isNotEmpty) parts.add(_addressCtrl.text.trim());
    if (_selectedCity.isNotEmpty) parts.add(_selectedCity);
    if (_selectedProvince.isNotEmpty) parts.add(_selectedProvince);
    return parts.join(', ');
  }

  Future<void> _save() async {
    if (_selectedProvince.isEmpty || _selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi provinsi dan kota'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    await HiveDb.instance.updateUserProfile({
      'phone': _phoneCtrl.text.trim(),
      'address': _buildFullAddress(),
      'province': _selectedProvince,
      'city': _selectedCity,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alamat berhasil diperbarui'), backgroundColor: AppColors.primaryBlack, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final result = await LocationHelper.detectLocation();
    if (!mounted) return;
    setState(() => _locating = false);

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    String? matchedProvince = result.province;
    if (matchedProvince != null && !IndonesiaRegions.provinces.contains(matchedProvince)) {
      matchedProvince = null;
    }

    String? matchedCity = result.city;
    List<String> citiesInProvince = matchedProvince != null
        ? List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince] ?? [])
        : <String>[];

    if (matchedCity != null) {
      final found = IndonesiaRegions.findMatchingCity(matchedCity, citiesInProvince);
      if (found != null) {
        matchedCity = found;
      } else if (matchedProvince != null) {
        final (prov, city) = IndonesiaRegions.findProvinceAndCity(matchedCity);
        if (prov != null && city != null) {
          matchedProvince = prov;
          matchedCity = city;
          citiesInProvince = List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince]!);
        } else {
          matchedCity = null;
        }
      } else {
        final (prov, city) = IndonesiaRegions.findProvinceAndCity(matchedCity);
        if (prov != null && city != null) {
          matchedProvince = prov;
          matchedCity = city;
          citiesInProvince = List<String>.from(IndonesiaRegions.citiesByProvince[matchedProvince]!);
        } else {
          matchedCity = null;
        }
      }
    }

    setState(() {
      _selectedProvince = matchedProvince ?? '';
      _cities = citiesInProvince;
      _selectedCity = matchedCity ?? '';
    });
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
        title: const Text('Alamat Pengiriman', style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.softGrey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Alamat ini akan digunakan untuk pengiriman pesanan kamu',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'No. Telepon',
                labelStyle: AppTextStyles.labelMedium,
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.charcoal, size: 20),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _detectLocation,
                icon: _locating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, size: 20),
                label: Text(_locating ? 'Mendeteksi lokasi...' : 'Deteksi Lokasi Saya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlack,
                  side: const BorderSide(color: AppColors.primaryBlack),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProvince.isEmpty ? null : _selectedProvince,
              decoration: InputDecoration(
                labelText: 'Provinsi',
                labelStyle: AppTextStyles.labelMedium,
                prefixIcon: Icon(Icons.map_outlined, color: AppColors.charcoal, size: 20),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
              items: IndonesiaRegions.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) {
                if (v != null) setState(() {
                  _selectedProvince = v;
                  _selectedCity = '';
                  _cities = IndonesiaRegions.citiesByProvince[v] ?? [];
                });
              },
              dropdownColor: AppColors.pureWhite,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCity.isEmpty ? null : _selectedCity,
              decoration: InputDecoration(
                labelText: 'Kota/Kabupaten',
                labelStyle: AppTextStyles.labelMedium,
                prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.charcoal, size: 20),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCity = v);
              },
              dropdownColor: AppColors.pureWhite,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Detail Alamat (jalan, gang, no. rumah)',
                labelStyle: AppTextStyles.labelMedium,
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.location_on_outlined, color: AppColors.charcoal, size: 20),
                ),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlack,
                  foregroundColor: AppColors.pureWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.pureWhite,
                        ),
                      )
                    : const Text('Simpan Alamat', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

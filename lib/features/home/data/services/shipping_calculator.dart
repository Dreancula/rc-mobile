import 'dart:math' as math;

class CourierOption {
  final String name;
  final String service;
  final String etd;
  final double cost;
  final double ratePerKgPerKm;

  const CourierOption({
    required this.name,
    required this.service,
    required this.etd,
    required this.cost,
    required this.ratePerKgPerKm,
  });
}

class ShippingResult {
  final List<CourierOption> options;
  final int estimatedDistanceKm;

  const ShippingResult({
    required this.options,
    required this.estimatedDistanceKm,
  });
}

class ShippingCalculator {
  static const String storeAddress =
      'Jl. Margonda No.8, Pondok Cina, Beji, Depok 16424';
  static const String storeCity = 'Depok';

  static final Map<String, int> _cityDistances = {
    'Jakarta': 30,
    'Jakarta Pusat': 28,
    'Jakarta Utara': 40,
    'Jakarta Barat': 35,
    'Jakarta Selatan': 25,
    'Jakarta Timur': 20,
    'Bogor': 50,
    'Depok': 5,
    'Tangerang': 60,
    'Tangerang Selatan': 45,
    'Bekasi': 35,
    'Bandung': 140,
    'Cimahi': 150,
    'Cirebon': 220,
    'Sukabumi': 120,
    'Karawang': 70,
    'Purwakarta': 90,
    'Subang': 130,
    'Indramayu': 200,
    'Cianjur': 110,
    'Garut': 180,
    'Tasikmalaya': 220,
    'Banjar': 260,
    'Pangandaran': 280,
    'Serang': 120,
    'Cilegon': 140,
    'Lampung': 300,
    'Palembang': 520,
    'Jambi': 720,
    'Pekanbaru': 950,
    'Padang': 1100,
    'Medan': 1500,
    'Aceh': 1900,
    'Pontianak': 1200,
    'Palangkaraya': 1400,
    'Banjarmasin': 1500,
    'Samarinda': 1600,
    'Balikpapan': 1650,
    'Makassar': 1800,
    'Manado': 2100,
    'Palu': 1900,
    'Kendari': 2000,
    'Gorontalo': 2200,
    'Ambon': 2500,
    'Jayapura': 4000,
    'Manokwari': 3500,
    'Denpasar': 1200,
    'Mataram': 1350,
    'Kupang': 1900,
    'Yogyakarta': 430,
    'Surakarta': 480,
    'Semarang': 510,
    'Magelang': 450,
    'Pekalongan': 360,
    'Tegal': 320,
    'Surabaya': 750,
    'Malang': 830,
    'Madiun': 630,
    'Kediri': 700,
    'Blitar': 780,
    'Jember': 950,
    'Banyuwangi': 1050,
    'Bali': 1200,
  };

  static int estimateDistance(String userAddress) {
    if (userAddress.isEmpty) return 150;

    String addr = userAddress.toLowerCase();
    String? matchedCity;
    int matchedLen = 0;

    for (final city in _cityDistances.keys) {
      if (addr.contains(city.toLowerCase())) {
        if (city.length > matchedLen) {
          matchedCity = city;
          matchedLen = city.length;
        }
      }
    }

    if (matchedCity != null) {
      return _cityDistances[matchedCity]!;
    }

    if (addr.contains('jawa barat') || addr.contains('jawabarat')) {
      return 100;
    }
    if (addr.contains('jawa tengah') || addr.contains('jawatengah')) {
      return 450;
    }
    if (addr.contains('jawa timur') || addr.contains('jawatimur')) {
      return 750;
    }
    if (addr.contains('sumatera') || addr.contains('sumatra')) {
      return 700;
    }
    if (addr.contains('kalimantan')) {
      return 1400;
    }
    if (addr.contains('sulawesi')) {
      return 1900;
    }
    if (addr.contains('papua')) {
      return 3500;
    }
    if (addr.contains('bali') || addr.contains('nusa')) {
      return 1200;
    }

    return 150;
  }

  static String formatDistance(int km) {
    if (km < 1) return '< 1 km';
    if (km >= 1000) return '${(km / 1000).toStringAsFixed(1)} rb km';
    return '$km km';
  }

  static List<CourierOption> calculateOptions(double totalWeightGrams, int distanceKm) {
    final weightKg = (totalWeightGrams / 1000).ceilToDouble().clamp(1, double.infinity);
    final options = <CourierOption>[];

    if (distanceKm <= 80) {
      options.add(CourierOption(
        name: 'GoSend',
        service: 'Same Day',
        etd: '1-4 Jam',
        cost: (8000 + weightKg * 3000 * (distanceKm / 10)).round().toDouble(),
        ratePerKgPerKm: 3000,
      ));
    }

    if (distanceKm <= 200) {
      options.add(CourierOption(
        name: 'SiCepat',
        service: 'BEST (Besok Sampai)',
        etd: '1 Hari',
        cost: (10000 + weightKg * 2500 * (distanceKm / 10)).round().toDouble(),
        ratePerKgPerKm: 2500,
      ));
    }

    options.add(CourierOption(
      name: 'SiCepat',
      service: 'REG (Regular)',
      etd: _etdText(distanceKm, 3, 6),
      cost: (8000 + weightKg * 1500 * math.max(distanceKm / 10, 1)).round().toDouble(),
      ratePerKgPerKm: 1500,
    ));

    options.add(CourierOption(
      name: 'JNE',
      service: 'REG (Regular)',
      etd: _etdText(distanceKm, 2, 5),
      cost: (9000 + weightKg * 1800 * math.max(distanceKm / 10, 1)).round().toDouble(),
      ratePerKgPerKm: 1800,
    ));

    options.add(CourierOption(
      name: 'J&T',
      service: 'Express',
      etd: _etdText(distanceKm, 2, 5),
      cost: (8000 + weightKg * 1700 * math.max(distanceKm / 10, 1)).round().toDouble(),
      ratePerKgPerKm: 1700,
    ));

    if (distanceKm > 80) {
      options.add(CourierOption(
        name: 'JNE',
        service: 'OKE (Ongkos Kirim Ekonomis)',
        etd: _etdText(distanceKm, 5, 10),
        cost: (7000 + weightKg * 1200 * math.max(distanceKm / 10, 1)).round().toDouble(),
        ratePerKgPerKm: 1200,
      ));
    }

    options.sort((a, b) => a.cost.compareTo(b.cost));
    return options;
  }

  static String _etdText(int distanceKm, int minDays, int maxDays) {
    if (distanceKm < 100) return '$minDays-${minDays + 1} Hari';
    if (distanceKm < 500) return '$minDays-${minDays + 2} Hari';
    if (distanceKm < 1000) return '${minDays + 1}-${minDays + 4} Hari';
    return '${minDays + 3}-${minDays + 7} Hari';
  }

  static ShippingResult calculate(
      String userAddress, double totalWeightGrams) {
    final distance = estimateDistance(userAddress);
    final options = calculateOptions(totalWeightGrams, distance);
    return ShippingResult(
      options: options,
      estimatedDistanceKm: distance,
    );
  }

  /// Calculate shipping using a known city name (bypasses address parsing).
  static ShippingResult calculateFromCity(
      String city, double totalWeightGrams) {
    final distance = _cityDistances[city] ?? estimateDistance(city);
    final options = calculateOptions(totalWeightGrams, distance);
    return ShippingResult(
      options: options,
      estimatedDistanceKm: distance,
    );
  }
}

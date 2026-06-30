class IndonesiaRegions {
  static const List<String> provinces = [
    'Aceh',
    'Bali',
    'Banten',
    'Bengkulu',
    'DI Yogyakarta',
    'DKI Jakarta',
    'Gorontalo',
    'Jambi',
    'Jawa Barat',
    'Jawa Tengah',
    'Jawa Timur',
    'Kalimantan Barat',
    'Kalimantan Selatan',
    'Kalimantan Tengah',
    'Kalimantan Timur',
    'Kalimantan Utara',
    'Kepulauan Bangka Belitung',
    'Kepulauan Riau',
    'Lampung',
    'Maluku',
    'Maluku Utara',
    'Nusa Tenggara Barat',
    'Nusa Tenggara Timur',
    'Papua',
    'Papua Barat',
    'Papua Barat Daya',
    'Papua Pegunungan',
    'Papua Selatan',
    'Papua Tengah',
    'Riau',
    'Sulawesi Barat',
    'Sulawesi Selatan',
    'Sulawesi Tengah',
    'Sulawesi Tenggara',
    'Sulawesi Utara',
    'Sumatera Barat',
    'Sumatera Selatan',
    'Sumatera Utara',
  ];

  static const Map<String, List<String>> citiesByProvince = {
    'Aceh': ['Banda Aceh', 'Aceh Besar', 'Aceh Timur', 'Aceh Utara'],
    'Bali': ['Denpasar', 'Badung', 'Gianyar', 'Buleleng', 'Tabanan'],
    'Banten': ['Serang', 'Cilegon', 'Tangerang', 'Tangerang Selatan', 'Pandeglang', 'Lebak'],
    'Bengkulu': ['Bengkulu'],
    'DI Yogyakarta': ['Yogyakarta', 'Sleman', 'Bantul', 'Kulon Progo', 'Gunung Kidul'],
    'DKI Jakarta': ['Jakarta Pusat', 'Jakarta Utara', 'Jakarta Barat', 'Jakarta Selatan', 'Jakarta Timur', 'Kepulauan Seribu'],
    'Gorontalo': ['Gorontalo'],
    'Jambi': ['Jambi'],
    'Jawa Barat': ['Bandung', 'Bogor', 'Depok', 'Bekasi', 'Cimahi', 'Cirebon', 'Sukabumi', 'Karawang', 'Purwakarta', 'Subang', 'Indramayu', 'Cianjur', 'Garut', 'Tasikmalaya', 'Banjar', 'Pangandaran', 'Sumedang', 'Majalengka', 'Kuningan'],
    'Jawa Tengah': ['Semarang', 'Surakarta', 'Magelang', 'Pekalongan', 'Tegal', 'Purwokerto', 'Salatiga', 'Kudus', 'Sragen', 'Solo'],
    'Jawa Timur': ['Surabaya', 'Malang', 'Madiun', 'Kediri', 'Blitar', 'Jember', 'Banyuwangi', 'Pasuruan', 'Probolinggo', 'Mojokerto', 'Tuban', 'Lamongan', 'Gresik', 'Sidoarjo'],
    'Kalimantan Barat': ['Pontianak', 'Singkawang', 'Ketapang'],
    'Kalimantan Selatan': ['Banjarmasin', 'Banjarbaru', 'Martapura'],
    'Kalimantan Tengah': ['Palangkaraya'],
    'Kalimantan Timur': ['Samarinda', 'Balikpapan', 'Bontang', 'Berau'],
    'Kalimantan Utara': ['Tarakan'],
    'Kepulauan Bangka Belitung': ['Pangkal Pinang'],
    'Kepulauan Riau': ['Batam', 'Tanjung Pinang'],
    'Lampung': ['Bandar Lampung', 'Metro', 'Lampung Tengah', 'Lampung Selatan'],
    'Maluku': ['Ambon'],
    'Maluku Utara': ['Ternate'],
    'Nusa Tenggara Barat': ['Mataram', 'Lombok Barat', 'Lombok Tengah', 'Lombok Timur'],
    'Nusa Tenggara Timur': ['Kupang', 'Flores', 'Sumba'],
    'Papua': ['Jayapura'],
    'Papua Barat': ['Manokwari'],
    'Papua Barat Daya': ['Sorong'],
    'Papua Pegunungan': ['Wamena'],
    'Papua Selatan': ['Merauke'],
    'Papua Tengah': ['Timika'],
    'Riau': ['Pekanbaru', 'Dumai'],
    'Sulawesi Barat': ['Mamuju'],
    'Sulawesi Selatan': ['Makassar', 'Parepare', 'Palopo'],
    'Sulawesi Tengah': ['Palu', 'Luwuk', 'Toli-Toli'],
    'Sulawesi Tenggara': ['Kendari', 'Baubau'],
    'Sulawesi Utara': ['Manado', 'Bitung', 'Tomohon'],
    'Sumatera Barat': ['Padang', 'Bukittinggi', 'Payakumbuh', 'Padang Panjang'],
    'Sumatera Selatan': ['Palembang', 'Prabumulih', 'Lubuklinggau'],
    'Sumatera Utara': ['Medan', 'Binjai', 'Pematangsiantar', 'Tebing Tinggi', 'Sibolga'],
  };


  /// Normalize city name (strip "Kota ", "Kabupaten " prefix).
  static String normalizeCity(String name) {
    final n = name.trim();
    if (n.startsWith('Kota ') && n.length > 5) return n.substring(5);
    if (n.startsWith('Kabupaten ') && n.length > 10) return n.substring(10);
    return n;
  }

  /// Find which province a city belongs to (case-insensitive).
  static String? findProvinceByCity(String cityName) {
    final c = normalizeCity(cityName).toLowerCase();
    for (final entry in citiesByProvince.entries) {
      if (entry.value.any((city) => city.toLowerCase() == c)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Find a matching city name from a list (case-insensitive, returns the canonical name).
  static String? findMatchingCity(String cityName, List<String> cities) {
    final c = normalizeCity(cityName).toLowerCase();
    for (final city in cities) {
      if (city.toLowerCase() == c) return city;
    }
    return null;
  }

  /// Search all provinces for a matching city, returns (province, city).
  static (String?, String?) findProvinceAndCity(String cityName) {
    final c = normalizeCity(cityName);
    final lower = c.toLowerCase();
    for (final entry in citiesByProvince.entries) {
      for (final city in entry.value) {
        if (city.toLowerCase() == lower) {
          return (entry.key, city);
        }
      }
    }
    return (null, null);
  }
}

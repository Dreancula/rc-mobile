import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final String? city;
  final String? province;
  final String? error;

  const LocationResult({this.city, this.province, this.error});
}

class LocationHelper {
  static Future<LocationResult> detectLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(error: 'Layanan lokasi tidak aktif. Aktifkan GPS Anda.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(error: 'Izin lokasi ditolak.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(error: 'Izin lokasi ditolak permanen. Aktifkan dari pengaturan.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return const LocationResult(error: 'Gagal mendapatkan alamat dari lokasi.');
      }

      final place = placemarks.first;
      final subAdmin = place.subAdministrativeArea;
      final admin = place.administrativeArea;

      String? city;
      String? province;

      if (subAdmin != null && subAdmin.isNotEmpty) {
        city = subAdmin;
      } else if (place.locality != null && place.locality!.isNotEmpty) {
        city = place.locality;
      }

      if (admin != null && admin.isNotEmpty) {
        province = admin;
      }

      if (city == null && province == null) {
        return const LocationResult(error: 'Tidak dapat mengenali kota/provinsi dari lokasi.');
      }

      return LocationResult(city: city, province: province);
    } catch (e) {
      return LocationResult(error: 'Gagal mendeteksi lokasi: $e');
    }
  }
}

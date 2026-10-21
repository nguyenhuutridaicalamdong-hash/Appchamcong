import 'package:geolocator/geolocator.dart';

class LocationService {
  // Tọa độ mẫu của Văn phòng Công ty Nguyễn Hữu Trí (Trung tâm TPHCM)
  static const double companyLatitude = 10.776889;
  static const double companyLongitude = 106.700806;
  static const double maxAllowedDistanceMeters = 300.0; // Bán kính cho phép chấm công: 300 mét

  // 1. Kiểm tra và yêu cầu quyền GPS
  static Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // 2. Lấy vị trí GPS hiện tại
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (_) {
      return null;
    }
  }

  // 3. Tính khoảng cách từ nhân viên tới công ty (mét)
  static double calculateDistanceToCompany(double userLat, double userLng) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      companyLatitude,
      companyLongitude,
    );
  }

  // 4. Kiểm tra xem có đang đứng trong bán kính công ty không
  static bool isWithinCompanyRadius(Position pos) {
    final distance = calculateDistanceToCompany(pos.latitude, pos.longitude);
    return distance <= maxAllowedDistanceMeters;
  }
}

import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // 1. Kiểm tra thiết bị có hỗ trợ Sinh trắc học (Khuôn mặt / Vân tay) không
  static Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  // 2. Thực hiện quét khuôn mặt / Sinh trắc học
  static Future<bool> authenticateWithFace() async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: 'Vui lòng xác thực vân tay hoặc khuôn mặt để đăng nhập',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../models/attendance_model.dart';

class ApiService {
  // Android Emulator kết nối với PC qua IP: 10.0.2.2:5184
  // Chrome / Windows kết nối qua: localhost:5184
  static String defaultBaseUrl = kIsWeb
      ? 'http://localhost:5184/api'
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:5184/api'
          : 'http://localhost:5184/api');

  static String baseUrl = defaultBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('custom_api_url');
    if (customUrl != null && customUrl.isNotEmpty) {
      baseUrl = customUrl;
      return;
    }

    // Tự động nhận diện kết nối: Thử localhost trước (cáp USB adb reverse / physical phone), nếu không được thì dùng 10.0.2.2 (máy ảo)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final res = await http.get(Uri.parse('http://localhost:5184/api/auth/me'))
            .timeout(const Duration(milliseconds: 1200));
        if (res.statusCode == 401 || res.statusCode == 200) {
          baseUrl = 'http://localhost:5184/api';
          return;
        }
      } catch (_) {
        // Fallback sang máy ảo emulator
      }
      baseUrl = 'http://10.0.2.2:5184/api';
    } else {
      baseUrl = defaultBaseUrl;
    }
  }

  static Future<void> setCustomBaseUrl(String url) async {
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_url', url);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('current_user');
    if (str != null) {
      return UserModel.fromJson(jsonDecode(str));
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('current_user');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _safeJsonDecode(http.Response res) {
    final text = utf8.decode(res.bodyBytes).trim();
    if (text.isEmpty) {
      return {'message': 'Server phản hồi rỗng (Mã lỗi HTTP: ${res.statusCode})'};
    }
    try {
      return jsonDecode(text);
    } catch (_) {
      return {'message': 'Mã lỗi HTTP: ${res.statusCode} - $text'};
    }
  }

  // ================= AUTH APIs =================

  // 1. Đăng ký tài khoản qua email
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String role = "Employee",
    String? department,
    String? position,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/Auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'role': role,
        'department': department,
        'position': position,
      }),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'data': data};
    }
    return {'success': false, 'message': data['message'] ?? 'Đăng ký thất bại'};
  }

  // 2. Đăng nhập bước 1: Username + Password -> Yêu cầu OTP
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/Auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {
        'success': true,
        'requireOtp': data['requireOtp'] ?? true,
        'username': data['username'],
        'email': data['email'],
        'demoOtp': data['demoOtp'],
      };
    }
    return {'success': false, 'message': data['message'] ?? 'Đăng nhập thất bại (HTTP ${res.statusCode})'};
  }

  // 3. Đăng nhập bước 2: Xác thực OTP -> Nhận Token + Role
  static Future<Map<String, dynamic>> verifyOtp({
    required String username,
    required String otpCode,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/Auth/verify-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'otpCode': otpCode,
      }),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final user = UserModel.fromJson(data);
      if (user.token != null) {
        await saveToken(user.token!);
      }
      await saveUser(user);
      return {'success': true, 'user': user};
    }
    return {'success': false, 'message': data['message'] ?? 'Xác thực OTP thất bại'};
  }

  // 4. Đăng nhập / Đăng ký nhanh bằng tài khoản Google (OAuth2)
  static Future<Map<String, dynamic>> googleLogin({
    required String email,
    required String fullName,
    String? googleId,
    String? avatarUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/Auth/google-login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'fullName': fullName,
        'googleId': googleId,
        'avatarUrl': avatarUrl,
      }),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final user = UserModel.fromJson(data);
      if (user.token != null) {
        await saveToken(user.token!);
      }
      await saveUser(user);
      return {'success': true, 'user': user};
    }
    return {'success': false, 'message': data['message'] ?? 'Đăng nhập Google thất bại'};
  }

  // ================= EMPLOYEE APIs (CRUD) =================

  static Future<List<EmployeeModel>> getEmployees({String? search, String? department}) async {
    var uri = Uri.parse('$baseUrl/Employee');
    Map<String, String> params = {};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (department != null && department.isNotEmpty) params['department'] = department;
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final res = await http.get(uri, headers: await _getHeaders());
    if (res.statusCode == 200) {
      List list = jsonDecode(utf8.decode(res.bodyBytes));
      return list.map((e) => EmployeeModel.fromJson(e)).toList();
    }
    throw Exception('Không thể tải danh sách nhân viên');
  }

  static Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$baseUrl/Employee'),
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'data': data};
    }
    return {'success': false, 'message': data['message'] ?? 'Thêm nhân viên thất bại'};
  }

  static Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse('$baseUrl/Employee/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Cập nhật thất bại'};
  }

  static Future<Map<String, dynamic>> deleteEmployee(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/Employee/$id'),
      headers: await _getHeaders(),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Xóa thất bại'};
  }

  // ================= ATTENDANCE APIs =================

  static Future<Map<String, dynamic>> checkIn({int? employeeId, String? note}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/Attendance/check-in'),
      headers: await _getHeaders(),
      body: jsonEncode({'employeeId': employeeId, 'note': note}),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'data': data};
    }
    return {'success': false, 'message': data['message'] ?? 'Check-in thất bại'};
  }

  static Future<Map<String, dynamic>> checkOut({int? employeeId, String? note}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/Attendance/check-out'),
      headers: await _getHeaders(),
      body: jsonEncode({'employeeId': employeeId, 'note': note}),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'data': data};
    }
    return {'success': false, 'message': data['message'] ?? 'Check-out thất bại'};
  }

  static Future<Map<String, dynamic>> getTodayStatus() async {
    final res = await http.get(
      Uri.parse('$baseUrl/Attendance/today'),
      headers: await _getHeaders(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return {'isCheckedIn': false, 'isCheckedOut': false};
  }

  static Future<List<AttendanceModel>> getMyHistory({int? month, int? year}) async {
    var uri = Uri.parse('$baseUrl/Attendance/my-history');
    Map<String, String> params = {};
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final res = await http.get(uri, headers: await _getHeaders());
    if (res.statusCode == 200) {
      List list = jsonDecode(utf8.decode(res.bodyBytes));
      return list.map((e) => AttendanceModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<AttendanceModel>> getAllAttendance() async {
    final res = await http.get(
      Uri.parse('$baseUrl/Attendance/all'),
      headers: await _getHeaders(),
    );
    if (res.statusCode == 200) {
      List list = jsonDecode(utf8.decode(res.bodyBytes));
      return list.map((e) => AttendanceModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<AttendanceReportModel?> getReport({int? month, int? year}) async {
    var uri = Uri.parse('$baseUrl/Attendance/report');
    Map<String, String> params = {};
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final res = await http.get(uri, headers: await _getHeaders());
    if (res.statusCode == 200) {
      return AttendanceReportModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    return null;
  }

  // Admin xóa bản ghi chấm công
  static Future<Map<String, dynamic>> deleteAttendance(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/Attendance/$id'),
      headers: await _getHeaders(),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Xóa chấm công thất bại'};
  }

  // Đặt lại (Reset) chấm công của ngày hôm nay
  static Future<Map<String, dynamic>> resetTodayAttendance({int? employeeId}) async {
    var uri = Uri.parse('$baseUrl/Attendance/reset-today');
    if (employeeId != null) {
      uri = uri.replace(queryParameters: {'employeeId': employeeId.toString()});
    }
    final res = await http.post(
      uri,
      headers: await _getHeaders(),
    );
    final data = _safeJsonDecode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Đặt lại thất bại'};
  }
}

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/employee/employee_dashboard.dart';
import 'screens/customer/customer_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  await ApiService.init();

  final token = await ApiService.getToken();
  final currentUser = await ApiService.getCurrentUser();

  runApp(AttendanceApp(
    initialUser: (token != null && currentUser != null) ? currentUser : null,
  ));
}

class AttendanceApp extends StatelessWidget {
  final UserModel? initialUser;

  const AttendanceApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Chấm Công - Nguyễn Hữu Trí',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    if (initialUser != null) {
      final role = initialUser!.role.toLowerCase();
      if (role == 'admin') {
        return AdminDashboard(user: initialUser!);
      } else if (role == 'employee') {
        return EmployeeDashboard(user: initialUser!);
      } else {
        return CustomerScreen(user: initialUser!);
      }
    }
    return const LoginScreen();
  }
}

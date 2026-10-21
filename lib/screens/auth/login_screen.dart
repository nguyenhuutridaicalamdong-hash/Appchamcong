import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard.dart';
import '../employee/employee_dashboard.dart';
import '../customer/customer_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'nhanvien1');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.login(
        username: username,
        password: password,
      );

      setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              username: res['username'] ?? username,
              email: res['email'] ?? '',
              demoOtp: res['demoOtp'],
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Đăng nhập không thành công'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối API: $e. Hãy chắc chắn Web API đang chạy!'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // ĐĂNG NHẬP BẰNG KHUÔN MẶT (FACE ID)
  void _handleFaceLogin() async {
    bool authenticated = await BiometricService.authenticateWithFace();

    if (!authenticated) {
      if (!mounted) return;
      authenticated = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _buildFaceScanDialog(ctx),
      ) ?? false;
    }

    if (authenticated) {
      setState(() => _isLoading = true);
      try {
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();
        final res = await ApiService.login(username: username, password: password);

        if (res['success'] == true && res['demoOtp'] != null) {
          final verifyRes = await ApiService.verifyOtp(username: username, otpCode: res['demoOtp']);
          setState(() => _isLoading = false);
          if (verifyRes['success'] == true && mounted) {
            final user = verifyRes['user'];
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xác thực khuôn mặt thành công! Đang chuyển hướng...'),
                backgroundColor: AppTheme.accent,
              ),
            );
            _navigateToRoleDashboard(user);
          }
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  // TÍNH NĂNG PHỤ: ĐĂNG NHẬP / ĐĂNG KÝ BẰNG GOOGLE (OAUTH2)
  void _handleGoogleSignIn() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.network(
                  'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (_, _, _) => const Icon(Icons.account_circle, color: Colors.blue, size: 32),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đăng nhập với Google',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn tài khoản Google để tiếp tục với App Chấm Công Nguyễn Hữu Trí:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // Tài khoản 1: Nguyễn Hữu Trí
            _buildGoogleAccountTile(
              name: 'Nguyễn Hữu Trí',
              email: 'nguyenhuutri.dev@gmail.com',
              avatarLetter: 'T',
              avatarColor: const Color(0xFF4285F4),
              onTap: () {
                Navigator.pop(ctx);
                _performGoogleLogin('nguyenhuutri.dev@gmail.com', 'Nguyễn Hữu Trí');
              },
            ),
            const Divider(height: 1),

            // Tài khoản 2: Nhân viên công ty
            _buildGoogleAccountTile(
              name: 'Nhân Viên Google',
              email: 'nhanvien.google@gmail.com',
              avatarLetter: 'G',
              avatarColor: const Color(0xFF34A853),
              onTap: () {
                Navigator.pop(ctx);
                _performGoogleLogin('nhanvien.google@gmail.com', 'Nhân Viên Google');
              },
            ),
            const Divider(height: 1),

            // Nhập email khác
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.person_add_alt_1_rounded, color: AppTheme.textSecondary, size: 20),
              ),
              title: const Text('Sử dụng một tài khoản Google khác', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showCustomGoogleEmailDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleAccountTile({
    required String name,
    required String email,
    required String avatarLetter,
    required Color avatarColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarColor,
        child: Text(avatarLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      onTap: onTap,
    );
  }

  void _showCustomGoogleEmailDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập tài khoản Google'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Google (@gmail.com)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final em = emailCtrl.text.trim();
              final nm = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Google User';
              if (em.contains('@')) {
                Navigator.pop(ctx);
                _performGoogleLogin(em, nm);
              }
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  void _performGoogleLogin(String email, String fullName) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.googleLogin(email: email, fullName: fullName);
      setState(() => _isLoading = false);

      if (res['success'] == true && mounted) {
        final user = res['user'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập Google thành công: ${user.fullName}'),
            backgroundColor: AppTheme.accent,
          ),
        );
        _navigateToRoleDashboard(user);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Đăng nhập Google thất bại'), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối API: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  void _navigateToRoleDashboard(dynamic user) {
    if (user.role.toString().toLowerCase() == 'admin') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => AdminDashboard(user: user)), (r) => false);
    } else if (user.role.toString().toLowerCase() == 'employee') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => EmployeeDashboard(user: user)), (r) => false);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => CustomerScreen(user: user)), (r) => false);
    }
  }

  Widget _buildFaceScanDialog(BuildContext ctx) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Xác Thực Vân Tay / Khuôn Mặt',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng chạm vào cảm biến vân tay hoặc hướng khuôn mặt vào camera',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 3),
                  color: AppTheme.primaryLight,
                ),
                child: const Center(
                  child: Icon(Icons.face_rounded, size: 84, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Xác nhận nhận diện khuôn mặt'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showApiSettings() {
    final urlController = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấu hình địa chỉ API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn nhanh cấu hình hoặc nhập IP:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Cáp USB (localhost)', style: TextStyle(fontSize: 11)),
                  onPressed: () => urlController.text = 'http://localhost:5184/api',
                ),
                ActionChip(
                  label: const Text('WiFi Laptop', style: TextStyle(fontSize: 11)),
                  onPressed: () => urlController.text = 'http://192.168.1.14:5184/api',
                ),
                ActionChip(
                  label: const Text('Máy ảo (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => urlController.text = 'http://10.0.2.2:5184/api',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                prefixIcon: Icon(Icons.link, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiService.setCustomBaseUrl(urlController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã cập nhật URL: ${ApiService.baseUrl}')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
                      onPressed: _showApiSettings,
                      tooltip: 'Cài đặt IP API',
                    ),
                  ),

                  const SizedBox(height: 10),
                  const SizedBox(height: 14),

                  const Text(
                    'App Chấm Công',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đăng nhập tài khoản để điểm danh và quản lý',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.admin_panel_settings, size: 16),
                        label: const Text('Admin mẫu', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          _usernameController.text = 'admin';
                          _passwordController.text = 'Admin@123';
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.badge, size: 16),
                        label: const Text('Nhân viên mẫu', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          _usernameController.text = 'nhanvien1';
                          _passwordController.text = '123456';
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập hoặc Email',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // NÚT ĐĂNG NHẬP CHÍNH (EMAIL/USERNAME + MẬT KHẨU -> OTP)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Tiếp tục (Nhận mã OTP)'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),

                  // NÚT ĐĂNG NHẬP BẰNG SINH TRẮC HỌC (VÂN TAY / KHUÔN MẶT)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppTheme.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleFaceLogin,
                    icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 22),
                    label: const Text(
                      'Đăng nhập bằng Vân tay / Khuôn mặt',
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ĐƯỜNG PHÂN CÁCH
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'HOẶC',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // TÍNH NĂNG PHỤ: NÚT TIẾP TỤC VỚI GOOGLE
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata, color: Colors.blue, size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tiếp tục với Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản? ', style: TextStyle(color: AppTheme.textSecondary)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

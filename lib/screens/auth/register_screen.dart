import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard.dart';
import '../employee/employee_dashboard.dart';
import '../customer/customer_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController(text: 'Kỹ Thuật');
  final _positionController = TextEditingController(text: 'Nhân viên phát triển');

  String _selectedRole = 'Employee';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  // LUỒNG CHÍNH: ĐĂNG KÝ BẰNG EMAIL & MẬT KHẨU
  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: _selectedRole,
        department: _deptController.text.trim(),
        position: _positionController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Đăng ký thành công!'),
            content: const Text(
              'Tài khoản của bạn đã được khởi tạo thành công. Vui lòng đăng nhập để bắt đầu sử dụng.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Đăng nhập ngay'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Đăng ký không thành công'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối API: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // TÍNH NĂNG PHỤ: ĐĂNG KÝ NHANH QUA GOOGLE
  void _handleGoogleSignUp() {
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
                  width: 30,
                  height: 30,
                  errorBuilder: (_, _, _) => const Icon(Icons.account_circle, color: Colors.blue, size: 30),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đăng ký nhanh với Google',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn tài khoản Google để tạo tài khoản nhân viên ngay lập tức:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),

            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF4285F4),
                child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: const Text('Nguyễn Hữu Trí', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('nguyenhuutri.dev@gmail.com', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _performGoogleRegister('nguyenhuutri.dev@gmail.com', 'Nguyễn Hữu Trí');
              },
            ),
            const Divider(height: 1),

            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF34A853),
                child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: const Text('Nhân Viên Google Mới', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('nhanvien.moi@gmail.com', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _performGoogleRegister('nhanvien.moi@gmail.com', 'Nhân Viên Google Mới');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _performGoogleRegister(String email, String fullName) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.googleLogin(email: email, fullName: fullName);
      setState(() => _isLoading = false);

      if (res['success'] == true && mounted) {
        final user = res['user'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo tài khoản Google thành công: ${user.fullName}'),
            backgroundColor: AppTheme.accent,
          ),
        );
        if (user.role.toString().toLowerCase() == 'admin') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => AdminDashboard(user: user)), (r) => false);
        } else if (user.role.toString().toLowerCase() == 'employee') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => EmployeeDashboard(user: user)), (r) => false);
        } else {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => CustomerScreen(user: user)), (r) => false);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Đăng ký thất bại'), backgroundColor: AppTheme.error),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản qua Email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tạo tài khoản mới',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nhập thông tin email để tạo tài khoản chấm công',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Họ và tên
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 16),

                    // Tên đăng nhập
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên đăng nhập *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'Vui lòng nhập email';
                        if (!v.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Số điện thoại
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mật khẩu
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => v!.trim().length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                    ),
                    const SizedBox(height: 20),

                    // Chọn vai trò
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò (Role) *',
                        prefixIcon: Icon(Icons.security_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Employee', child: Text('Nhân viên (Employee)')),
                        DropdownMenuItem(value: 'Admin', child: Text('Quản trị viên (Admin)')),
                        DropdownMenuItem(value: 'Customer', child: Text('Khách hàng (Customer)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_selectedRole == 'Employee') ...[
                      TextFormField(
                        controller: _deptController,
                        decoration: const InputDecoration(
                          labelText: 'Phòng ban',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: 'Chức vụ',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 12),

                    // NÚT ĐĂNG KÝ CHÍNH
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Hoàn tất đăng ký'),
                    ),
                    const SizedBox(height: 16),

                    // TÍNH NĂNG PHỤ: ĐĂNG KÝ NHANH GOOGLE
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('HOẶC', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleSignUp,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata, color: Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Đăng ký nhanh bằng Google',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Đã có tài khoản? ', style: TextStyle(color: AppTheme.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Đăng nhập ngay',
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
      ),
    );
  }
}
